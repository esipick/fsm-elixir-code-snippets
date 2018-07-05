defmodule Flight.Billing do
  alias Flight.Repo
  import Ecto.Query, warn: false
  import Pipe

  alias Flight.Billing

  alias Flight.Billing.{
    Transaction,
    TransactionLineItem,
    AircraftLineItemDetail,
    InstructorLineItemDetail
  }

  alias Flight.Accounts.{User}
  alias FlightWeb.API.{DetailedTransactionForm, CustomTransactionForm}

  def aircraft_cost!(%AircraftLineItemDetail{} = detail) do
    {:ok, amount} = aircraft_cost(detail)
    amount
  end

  def aircraft_cost(%AircraftLineItemDetail{} = detail) do
    aircraft_cost(
      detail.hobbs_start,
      detail.hobbs_end,
      detail.rate,
      detail.fee_percentage
    )
  end

  def aircraft_cost(hobbs_start, hobbs_end, rate, fee_percentage \\ 0.01) do
    cond do
      hobbs_end <= hobbs_start ->
        {:error, :invalid_hobbs_interval}

      true ->
        {:ok,
         (rate * (1 + fee_percentage) * ((hobbs_end - hobbs_start) / 10.0))
         |> trunc()}
    end
  end

  def aircraft_cost!(hobbs_start, hobbs_end, rate, fee_percentage \\ 0.01) do
    case aircraft_cost(hobbs_start, hobbs_end, rate, fee_percentage) do
      {:ok, amount} -> amount
      {:error, reason} -> raise ArgumentError, "Failed to compute aircraft cost: #{reason}"
    end
  end

  def instructor_cost!(%InstructorLineItemDetail{} = detail) do
    {:ok, amount} = instructor_cost(detail)
    amount
  end

  def instructor_cost(%InstructorLineItemDetail{} = detail) do
    instructor_cost(detail.billing_rate, detail.hour_tenths)
  end

  def instructor_cost(rate, tenths_of_an_hour) do
    cond do
      tenths_of_an_hour <= 0 -> {:error, :invalid_hours}
      true -> {:ok, (rate * (tenths_of_an_hour / 10.0)) |> trunc()}
    end
  end

  def instructor_cost!(rate, tenths_of_an_hour) do
    case instructor_cost(rate, tenths_of_an_hour) do
      {:ok, amount} -> amount
      {:error, reason} -> raise ArgumentError, "Failed to compute instructor cost: #{reason}"
    end
  end

  def rate_type_for_form(%DetailedTransactionForm{} = form) do
    {%{total: blockTotal}, _, _, _, _} = DetailedTransactionForm.to_transaction(form, :block)

    user = Flight.Accounts.get_user(form.user_id)

    if user.balance >= blockTotal do
      :block
    else
      :normal
    end
  end

  def create_transaction_from_detailed_form(form) do
    rate_type = rate_type_for_form(form)

    {transaction, instructor_line_item, instructor_details, aircraft_line_item, aircraft_details} =
      DetailedTransactionForm.to_transaction(form, rate_type)

    result =
      Repo.transaction(fn ->
        {:ok, transaction} = Repo.insert(Transaction.changeset(transaction, %{}))

        if form.appointment_id do
          appointment = Repo.get!(Flight.Scheduling.Appointment, form.appointment_id)

          {:ok, _} =
            appointment
            |> Flight.Scheduling.Appointment.update_transaction_changeset(%{
              transaction_id: transaction.id
            })
            |> Repo.update()
        end

        if instructor_line_item && instructor_details do
          {:ok, instructor_line_item} =
            instructor_line_item
            |> TransactionLineItem.changeset(%{transaction_id: transaction.id})
            |> Repo.insert()

          {:ok, _} =
            instructor_details
            |> InstructorLineItemDetail.changeset(%{
              transaction_line_item_id: instructor_line_item.id
            })
            |> Repo.insert()
        end

        if aircraft_line_item && aircraft_details do
          {:ok, aircraft_line_item} =
            aircraft_line_item
            |> TransactionLineItem.changeset(%{transaction_id: transaction.id})
            |> Repo.insert()

          {:ok, aircraft_details} =
            aircraft_details
            |> AircraftLineItemDetail.changeset(%{transaction_line_item_id: aircraft_line_item.id})
            |> Repo.insert()

          aircraft =
            from(
              a in Flight.Scheduling.Aircraft,
              where: a.id == ^aircraft_details.aircraft_id,
              lock: "FOR UPDATE"
            )
            |> Repo.one()

          if !aircraft do
            Repo.rollback("Aircraft does not exist")
          end

          new_hobbs_time = max(aircraft.last_hobbs_time, aircraft_details.hobbs_end)
          new_tach_time = max(aircraft.last_tach_time, aircraft_details.tach_end)

          {:ok, _} =
            aircraft
            |> Flight.Scheduling.Aircraft.changeset(%{
              last_tach_time: new_tach_time,
              last_hobbs_time: new_hobbs_time
            })
            |> Flight.Repo.update()
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

  def create_transaction_from_custom_form(form) do
    {transaction, line_item} = CustomTransactionForm.to_transaction(form)

    result =
      Repo.transaction(fn ->
        {:ok, transaction} =
          transaction
          |> Transaction.changeset(%{})
          |> Repo.insert()

        {:ok, _} =
          line_item
          |> TransactionLineItem.changeset(%{transaction_id: transaction.id})
          |> Repo.insert()

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
        &where(
          &1,
          [t],
          t.creator_user_id == ^params["creator_user_id"] and
            t.user_id != ^params["creator_user_id"]
        )
      )
      |> order_by([t], desc: t.inserted_at)

    Repo.all(query)
  end

  def parse_amount(str) when is_binary(str) do
    case Float.parse(str) do
      {float, _} -> {:ok, (float * 100) |> trunc()}
      :error -> {:error, :invalid}
    end
  end

  def parse_amount(num) when is_float(num) or is_integer(num) do
    {:ok, (num * 100) |> trunc()}
  end

  def parse_amount(_) do
    {:error, :invalid}
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
            completed_at: NaiveDateTime.utc_now(),
            state: "completed",
            type: "credit",
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

  def add_funds_by_credit(user, creator_user, amount) when is_integer(amount) do
    {:ok, result} =
      Repo.transaction(fn ->
        transaction =
          %Transaction{}
          |> Transaction.changeset(%{
            user_id: user.id,
            creator_user_id: creator_user.id,
            completed_at: NaiveDateTime.utc_now(),
            state: "completed",
            type: "credit",
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
      end)

    result
  end

  def add_funds_by_credit(user, creator_user, amount) when is_integer(amount) do
    transaction =
      %Transaction{}
      |> Transaction.changeset(%{
        user_id: user.id,
        creator_user_id: creator_user.id,
        completed_at: NaiveDateTime.utc_now(),
        state: "completed",
        type: "credit",
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
            type: "debit",
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
