defmodule Flight.Billing do
  alias Flight.Repo
  import Ecto.Query, warn: false
  import Pipe

  alias Flight.Billing
  alias Flight.SchoolScope

  alias Flight.Billing.{
    Transaction,
    TransactionLineItem,
    AircraftLineItemDetail,
    InstructorLineItemDetail
  }

  alias Flight.Accounts.{User, StripeAccount}
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

  def rate_type_for_form(%DetailedTransactionForm{} = form, school_context) do
    {%{total: blockTotal}, _, _, _, _} =
      DetailedTransactionForm.to_transaction(form, :block, school_context)

    user = Flight.Accounts.get_user(form.user_id, school_context)

    if user.balance >= blockTotal do
      :block
    else
      :normal
    end
  end

  def create_transaction_from_detailed_form(form, school_context) do
    rate_type = rate_type_for_form(form, school_context)

    {transaction, instructor_line_item, instructor_details, aircraft_line_item, aircraft_details} =
      DetailedTransactionForm.to_transaction(form, rate_type, school_context)

    result =
      Repo.transaction(fn ->
        {:ok, transaction} =
          transaction
          |> SchoolScope.school_changeset(school_context)
          |> Transaction.changeset(%{})
          |> Repo.insert()

        if form.appointment_id do
          appointment = Flight.Scheduling.get_appointment(form.appointment_id, school_context)

          if !appointment do
            Repo.rollback("Appointment does not exist")
          end

          if appointment.transaction_id do
            Repo.rollback("Appointment already has associated transaction")
          end

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
              where: a.school_id == ^Flight.SchoolScope.school_id(school_context),
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
        approve_transaction_if_necessary(transaction, form.source)

      error ->
        error
    end
  end

  def create_transaction_from_custom_form(form, school_context) do
    {transaction, line_item} = CustomTransactionForm.to_transaction(form, school_context)

    result =
      Repo.transaction(fn ->
        {:ok, transaction} =
          transaction
          |> SchoolScope.school_changeset(school_context)
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
        approve_transaction_if_necessary(transaction, form.source)

      error ->
        error
    end
  end

  def approve_transaction_if_necessary(transaction, source) do
    transaction = Repo.preload(transaction, [:user])

    if transaction.creator_user_id == transaction.user_id ||
         preferred_payment_method(transaction.user, transaction.total) == :balance do
      transaction
      |> Repo.preload([:user, :creator_user])
      |> approve_transaction(source)
    else
      {:ok, transaction}
    end
  end

  def get_transaction(id, school_context) do
    Transaction
    |> SchoolScope.scope_query(school_context)
    |> where([t], t.id == ^id)
    |> Repo.one()
  end

  def get_filtered_transactions(params, school_context) do
    params = Map.take(params, ["user_id", "creator_user_id", "state"])

    query =
      from(t in Transaction)
      |> SchoolScope.scope_query(school_context)
      |> where([t], t.state != "canceled")
      |> pass_unless(params["state"], &where(&1, [t], t.state == ^params["state"]))
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

  def add_funds_by_charge(user, creator_user, amount, source)
      when is_integer(amount) and amount > 0 do
    result = create_stripe_charge(source, user.stripe_customer_id, user.email, amount, user)

    case result do
      {:ok, charge} ->
        transaction =
          %Transaction{}
          |> SchoolScope.school_changeset(user)
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

  def add_funds_by_credit(user, creator_user, amount) when is_integer(amount) and amount > 0 do
    {:ok, result} =
      Repo.transaction(fn ->
        transaction =
          %Transaction{}
          |> SchoolScope.school_changeset(user)
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
      |> SchoolScope.school_changeset(user)
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

  def cancel_transaction(transaction) do
    case transaction.state do
      "pending" ->
        {:ok, result} =
          Repo.transaction(fn ->
            appointment =
              Flight.Repo.get_by(Flight.Scheduling.Appointment, transaction_id: transaction.id)

            if appointment do
              appointment
              |> Flight.Scheduling.Appointment.update_transaction_changeset(%{transaction_id: nil})
              |> Repo.update()
            end

            transaction
            |> Transaction.changeset(%{state: "canceled"})
            |> Repo.update()
          end)

        result

      _ ->
        {:error, :cannot_cancel_non_pending_transaction}
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

        if new_balance >= 0 do
          user
          |> User.balance_changeset(%{balance: new_balance})
          |> Repo.update()
        else
          {:error, :negative_balance}
        end
      end)

    result
  end

  def get_stripe_account_by_account_id(account_id) do
    from(s in StripeAccount)
    |> where([s], s.stripe_account_id == ^account_id)
    |> Repo.one()
  end

  def update_stripe_account(
        %StripeAccount{} = account,
        %Stripe.Account{} = api_account
      ) do
    account
    |> StripeAccount.changeset(%{
      details_submitted: api_account.details_submitted,
      payouts_enabled: api_account.payouts_enabled,
      charges_enabled: api_account.charges_enabled
    })
    |> Flight.Repo.update()
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

  def create_stripe_customer(email, school_context) do
    stripe_account =
      Repo.get_by(
        Flight.Accounts.StripeAccount,
        school_id: SchoolScope.school_id(school_context)
      )

    if stripe_account do
      Stripe.Customer.create(%{email: email}, connect_account: stripe_account.stripe_account_id)
    else
      {:error, :no_stripe_account}
    end
  end

  def create_card(user, token, school_context) when is_binary(token) do
    stripe_account =
      Repo.get_by(
        Flight.Accounts.StripeAccount,
        school_id: SchoolScope.school_id(school_context)
      )

    if stripe_account do
      Stripe.Card.create(
        %{customer: user.stripe_customer_id, source: token},
        connect_account: stripe_account.stripe_account_id
      )
    else
      {:error, :no_stripe_account}
    end
  end

  def create_deferred_stripe_account(email) do
    Stripe.Account.create(%{
      country: "US",
      type: "standard",
      email: email
    })
  end

  def create_stripe_charge(source_id, transaction) do
    case transaction.state do
      "pending" ->
        create_stripe_charge(
          source_id,
          transaction.user.stripe_customer_id,
          transaction.user.email,
          transaction.total,
          transaction
        )

      _ ->
        {:error, :cannot_charge_non_pending_transaction}
    end
  end

  def create_stripe_charge(source_id, customer_id, email, total, school_context) do
    stripe_account =
      Repo.get_by(
        Flight.Accounts.StripeAccount,
        school_id: SchoolScope.school_id(school_context)
      )

    cond do
      !stripe_account ->
        {:error, :no_stripe_account}

      !stripe_account.charges_enabled ->
        {:error, :charges_disabled}

      true ->
        Stripe.Charge.create(
          %{
            source: source_id,
            customer: customer_id,
            currency: "usd",
            receipt_email: email,
            amount: total
          },
          connect_account: stripe_account.stripe_account_id
        )
    end
  end

  def create_ephemeral_key(customer_id, api_version, school_context) do
    stripe_account =
      Repo.get_by(
        Flight.Accounts.StripeAccount,
        school_id: SchoolScope.school_id(school_context)
      )

    if stripe_account do
      Stripe.EphemeralKey.create(
        %{customer: customer_id},
        api_version,
        connect_account: stripe_account.stripe_account_id
      )
    else
      {:error, :no_stripe_account}
    end
  end
end
