defmodule Flight.Billing do
  alias Flight.Repo
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Pipe

  alias Flight.Billing

  alias Flight.Billing.{Transaction, TransactionLineItem, AircraftLineItemDetail}
  alias Flight.Accounts.{User}
  alias FlightWeb.API.DetailedTransactionForm

  def aircraft_cost(aircraft, hobbs_start, hobbs_end, fee_percentage \\ 0.01) do
    cond do
      hobbs_end <= hobbs_start ->
        {:error, :invalid_hobbs_interval}

      true ->
        {:ok,
         (aircraft.rate_per_hour * (1 + fee_percentage) * ((hobbs_end - hobbs_start) / 10.0 * 100))
         |> trunc()}
    end
  end

  def aircraft_cost!(aircraft, hobbs_start, hobbs_end, fee_percentage \\ 0.1) do
    case aircraft_cost(aircraft, hobbs_start, hobbs_end, fee_percentage) do
      {:ok, amount} -> amount
      {:error, reason} -> raise ArgumentError, "Failed to compute aircraft cost: #{reason}"
    end
  end

  def instructor_cost(instructor, tenths_of_an_hour) do
    cond do
      tenths_of_an_hour <= 0 -> {:error, :invalid_hours}
      true -> {:ok, (instructor.billing_rate * (tenths_of_an_hour / 10.0) * 100) |> trunc()}
    end
  end

  def instructor_cost!(instructor, tenths_of_an_hour) do
    case instructor_cost(instructor, tenths_of_an_hour) do
      {:ok, amount} -> amount
      {:error, reason} -> raise ArgumentError, "Failed to compute instructor cost: #{reason}"
    end
  end

  def create_transaction_from_detailed_form(form) do
    {transaction, instructor_line_item, aircraft_line_item, aircraft_details} =
      DetailedTransactionForm.to_transaction(form)

    result =
      Repo.transaction(fn ->
        {:ok, transaction} = Repo.insert(Transaction.changeset(transaction, %{}))

        if instructor_line_item do
          {:ok, _} =
            instructor_line_item
            |> TransactionLineItem.changeset(%{transaction_id: transaction.id})
            |> Repo.insert()
        end

        if aircraft_line_item && aircraft_details do
          {:ok, aircraft_line_item} =
            aircraft_line_item
            |> TransactionLineItem.changeset(%{transaction_id: transaction.id})
            |> Repo.insert()

          {:ok, _} =
            aircraft_details
            |> AircraftLineItemDetail.changeset(%{transaction_line_item_id: aircraft_line_item.id})
            |> Repo.insert()
        end

        transaction
      end)

    case result do
      {:ok, transaction} ->
        if form.creator_user_id == form.user_id do
          transaction
          |> Repo.preload([:user, :creator_user])
          |> approve_transaction(form.source)
        else
          {:ok, transaction}
        end

      error ->
        error
    end
  end

  def get_transaction(id) do
    Repo.get(Transaction, id)
  end

  def get_filtered_transactions(params) do
    params = Map.take(params, ["user_id", "creator_user_id"])

    query =
      from(t in Transaction)
      |> pass_unless(params["user_id"], &where(&1, [t], t.user_id == ^params["user_id"]))
      |> pass_unless(
        params["creator_user_id"],
        &where(&1, [t], t.creator_user_id == ^params["creator_user_id"])
      )
      |> order_by([t], desc: t.inserted_at)

    Repo.all(query)
  end

  def add_funds_by_charge(user, creator_user, amount, source) when is_integer(amount) do
    result = create_stripe_charge(source, user.stripe_customer_id, user.email, amount)

    case result do
      {:ok, charge} ->
        transaction =
          %Transaction{}
          |> Transaction.changeset(%{
            user_id: user.id,
            creator_user_id: creator_user.id,
            state: "completed",
            paid_by_charge: amount,
            stripe_charge_id: charge.id,
            total: amount
          })
          |> Repo.insert!()

        line_item =
          %TransactionLineItem{}
          |> TransactionLineItem.changeset(%{
            transaction_id: transaction.id,
            description: "Added funds to balance.",
            amount: amount
          })
          |> Repo.insert!()

        {:ok, user} = Billing.update_balance(user, amount)

        transaction = %{transaction | line_items: [line_item]}

        {:ok, {user, transaction}}

      error ->
        error
    end
  end

  def approve_transaction(transaction, source? \\ nil) do
    case transaction.state do
      "pending" ->
        case Billing.preferred_payment_method(transaction.user, transaction.total) do
          :balance ->
            with {:ok, _user} <- Billing.update_balance(transaction.user, -transaction.total),
                 {:ok, transaction} <- Billing.update_transaction_completed(transaction, :balance) do
              {:ok, transaction}
            else
              error -> error
            end

          :charge ->
            if source? do
              case Billing.create_stripe_charge(source?, transaction) do
                {:ok, charge} ->
                  Billing.update_transaction_completed(transaction, :charge, charge.id)

                error ->
                  error
              end
            else
              {:error, :must_provide_source}
            end
        end

      _ ->
        {:error, :cannot_approve_non_pending_transaction}
    end
  end

  def update_transaction_completed(transaction, paid_by, charge_id \\ nil) do
    case transaction.state do
      "pending" ->
        paid_by_key =
          case paid_by do
            :balance -> :paid_by_balance
            :charge -> :paid_by_charge
          end

        transaction
        |> Transaction.changeset(
          %{
            state: "completed",
            completed_at: NaiveDateTime.utc_now(),
            stripe_charge_id: charge_id
          }
          |> Map.put(paid_by_key, transaction.total)
        )
        |> Repo.update()

      _ ->
        {:error, :cannot_complete_non_pending_transaction}
    end
  end

  def update_balance(user, amount) do
    {:ok, result} =
      Repo.transaction(fn ->
        user =
          from(u in User, where: u.id == ^user.id, lock: "FOR UPDATE")
          |> Repo.one()

        new_balance = user.balance + amount

        if new_balance > 0 do
          user
          |> User.balance_changeset(%{balance: new_balance})
          |> Repo.update()
        else
          {:error, :negative_balance}
        end
      end)

    result
  end

  ###
  # Stripe
  ###

  def preferred_payment_method(user, amount) do
    if user.balance >= amount do
      :balance
    else
      :charge
    end
  end

  def create_stripe_customer(email) do
    Stripe.Customer.create(%{email: email})
  end

  def create_card(user, token) do
    Stripe.Card.create(%{customer: user.stripe_customer_id, source: token})
  end

  def create_stripe_charge(source_id, transaction) do
    case transaction.state do
      "pending" ->
        create_stripe_charge(
          source_id,
          transaction.user.stripe_customer_id,
          transaction.user.email,
          transaction.total
        )

      _ ->
        {:error, :cannot_charge_non_pending_transaction}
    end
  end

  def create_stripe_charge(source_id, customer_id, email, total) do
    Stripe.Charge.create(%{
      source: source_id,
      customer: customer_id,
      currency: "usd",
      receipt_email: email,
      amount: total
    })
  end

  def create_ephemeral_key(customer_id, api_version) do
    Stripe.EphemeralKey.create(%{customer: customer_id}, api_version)
    # Stripy.req(:post, "ephemeral_keys", %{customer: customer_id, stripe_version: api_version})
    # |> Stripy.parse()
  end
end
