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

  def aircraft_cost(hobbs_start, hobbs_end, rate, fee_percentage) do
    cond do
      hobbs_end <= hobbs_start ->
        {:error, :invalid_hobbs_interval}

      true ->
        {:ok,
         (rate * (1 + fee_percentage) * ((hobbs_end - hobbs_start) / 10.0))
         |> trunc()}
    end
  end

  def aircraft_cost!(hobbs_start, hobbs_end, rate, fee_percentage) do
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

    user =
      if form.user_id do
        Flight.Accounts.get_user(form.user_id, school_context)
      end

    if user && user.balance >= blockTotal do
      :block
    else
      :normal
    end
  end

  def platform_income() do
    from(c in Billing.PlatformCharge, select: sum(c.amount))
    |> Repo.all()
    |> List.first() || 0
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

          # Randon wants to try doing most recent updated value instead of highest value, so
          # commenting this out for now.
          # new_hobbs_time = max(aircraft.last_hobbs_time, aircraft_details.hobbs_end)
          # new_tach_time = max(aircraft.last_tach_time, aircraft_details.tach_end)

          {:ok, _} =
            aircraft
            |> Flight.Scheduling.Aircraft.changeset(%{
              last_tach_time: aircraft_details.tach_end,
              last_hobbs_time: aircraft_details.hobbs_end
            })
            |> Flight.Repo.update()
        end

        transaction
      end)

    with {:ok, transaction} <- result,
         {:ok, transaction} <- approve_transaction_if_necessary(transaction, form.source) do
      send_payment_notification(transaction)

      {:ok, transaction}
    else
      error -> error
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

    with {:ok, transaction} <- result,
         {:ok, transaction} <- approve_transaction_if_necessary(transaction, form.source) do
      send_payment_notification(transaction)

      {:ok, transaction}
    else
      error ->
        error
    end
  end

  def send_payment_notification(transaction) do
    Mondo.Task.start(fn ->
      transaction =
        transaction
        |> Repo.preload([:user, :creator_user])

      case transaction.state do
        "pending" ->
          Flight.PushNotifications.payment_request_notification(
            transaction.user,
            transaction.creator_user,
            transaction
          )
          |> Mondo.PushService.publish()

        "completed" ->
          if transaction.user_id && transaction.creator_user_id != transaction.user_id do
            cond do
              transaction.paid_by_balance ->
                Flight.PushNotifications.balance_deducted_notification(
                  transaction.user,
                  transaction.creator_user,
                  transaction
                )
                |> Mondo.PushService.publish()

              transaction.paid_by_charge ->
                Flight.PushNotifications.credit_card_charged_notification(
                  transaction.user,
                  transaction.creator_user,
                  transaction
                )
                |> Mondo.PushService.publish()

              transaction.paid_by_cash ->
                Flight.PushNotifications.cash_payment_received_notification(
                  transaction.user,
                  transaction.creator_user,
                  transaction
                )
                |> Mondo.PushService.publish()
            end
          end

        _ ->
          :nothing
      end
    end)
  end

  def approve_transaction_if_necessary(transaction, source) do
    transaction =
      transaction
      |> Repo.preload([:user, :creator_user], force: true)

    payment_method = get_payment_method(transaction.user, transaction.total, source)

    source =
      cond do
        source ->
          source

        payment_method == :charge && !source ->
          {:ok, customer} = get_stripe_customer(transaction.user)

          customer.default_source

        true ->
          nil
      end

    cond do
      payment_method == :cash || payment_method == :balance ||
          (source && payment_method == :charge) ->
        transaction
        |> Repo.preload([:user, :creator_user])
        |> approve_transaction(source)

      true ->
        {:ok, transaction}
    end
  end

  def approve_transaction(transaction, source? \\ nil) do
    case transaction.state do
      "pending" ->
        case get_payment_method(transaction.user, transaction.total, source?) do
          :cash ->
            with {:ok, transaction} <- update_transaction_completed(transaction, :cash) do
              {:ok, transaction}
            else
              error -> error
            end

          :balance ->
            with {:ok, _user} <- update_balance(transaction.user, -transaction.total),
                 {:ok, transaction} <- update_transaction_completed(transaction, :balance) do
              {:ok, transaction}
            else
              error -> error
            end

          :charge ->
            if source? do
              case create_stripe_charge(source?, transaction) do
                {:ok, charge} ->
                  update_transaction_completed(transaction, :charge, charge.id)

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

  def approve_transactions_within_balance(user) do
    get_filtered_transactions(%{"user_id" => user.id, "state" => "pending"}, user)
    |> Enum.map(fn transaction ->
      with :balance <- get_payment_method(user, transaction.total),
           {:ok, %Transaction{state: "completed"} = transaction} <-
             approve_transaction_if_necessary(transaction, nil) do
        send_payment_notification(transaction)
        transaction
      else
        _ ->
          transaction
      end
    end)
  end

  def get_transaction(id, school_context) do
    Transaction
    |> SchoolScope.scope_query(school_context)
    |> where([t], t.id == ^id)
    |> Repo.one()
  end

  def get_filtered_transactions(params, school_context) do
    params = Map.take(params, ["user_id", "creator_user_id", "state", "search_term"])
    {_, parsed_search_term} = parse_amount(params["search_term"])
    total = is_number(parsed_search_term) && params["search_term"]

    user_ids =
      params["search_term"] &&
        !is_number(parsed_search_term) &&
        Flight.Queries.User.search_users_ids_by_name(params["search_term"], school_context)

    query =
      from(t in Transaction)
      |> SchoolScope.scope_query(school_context)
      |> where([t], t.state != "canceled")
      |> where([t], not is_nil(t.user_id))
      |> pass_unless(params["state"], &where(&1, [t], t.state == ^params["state"]))
      |> pass_unless(params["user_id"], &where(&1, [t], t.user_id == ^params["user_id"]))
      |> pass_unless(user_ids, &where(&1, [t], t.user_id in ^user_ids))
      |> pass_unless(total, &where(&1, [t], fragment("?::text ILIKE ?", t.total, ^"%#{total}%")))
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

  def calculate_amount_spent_in_transactions(transactions) do
    Enum.reduce(transactions, 0, fn m, acc ->
      line_items = Map.get(m, :line_items) || []

      if (List.first(line_items) != nil &&
            Map.get(List.first(line_items), :type) not in ["add_funds", "remove_funds"]) ||
           List.first(line_items) == nil do
        (Map.get(m, :total) || 0) + acc
      else
        0 + acc
      end
    end)
  end

  def parse_amount(str) when is_binary(str) do
    case Float.parse(String.replace(str, ~r/,/, "")) do
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
    result = create_stripe_charge(source, user, user.email, amount, user)

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
            type: "add_funds",
            amount: amount
          })
          |> Repo.insert!()

        {:ok, user} = update_balance(user, amount)

        transaction = %{transaction | line_items: [line_item]}

        {:ok, {user, transaction}}

      error ->
        error
    end
  end

  def add_funds_by_credit(user, creator_user, amount, description)
      when is_integer(amount) and (amount > 0 or amount < 0) do
    {transaction_type, line_item_type} =
      if amount > 0 do
        {"credit", "add_funds"}
      else
        {"debit", "remove_funds"}
      end

    {:ok, result} =
      Repo.transaction(fn ->
        transaction =
          %Transaction{}
          |> SchoolScope.school_changeset(user)
          |> Transaction.changeset(
            %{
              user_id: user.id,
              creator_user_id: creator_user.id,
              completed_at: NaiveDateTime.utc_now(),
              state: "completed",
              type: transaction_type,
              total: abs(amount)
            }
            |> pass_unless(
              transaction_type == "debit",
              &Map.put(&1, :paid_by_balance, abs(amount))
            )
          )
          |> Repo.insert!()

        line_item =
          %TransactionLineItem{}
          |> TransactionLineItem.changeset(%{
            transaction_id: transaction.id,
            type: line_item_type,
            description: description,
            amount: abs(amount)
          })
          |> Repo.insert!()

        case update_balance(user, amount) do
          {:ok, user} ->
            transaction = %{transaction | line_items: [line_item]}

            {:ok, {user, transaction}}

          other ->
            other
        end
      end)

    case result do
      {:ok, {_, transaction}} ->
        Mondo.Task.start(fn ->
          transaction =
            transaction
            |> Repo.preload([:user])

          notification =
            if transaction.type == "credit" do
              Flight.PushNotifications.funds_added_notification(
                transaction.user,
                creator_user,
                transaction
              )
            else
              Flight.PushNotifications.funds_removed_notification(
                transaction.user,
                creator_user,
                transaction
              )
            end

          Mondo.PushService.publish(notification)
        end)

      _ ->
        :nothing
    end

    result
  end

  def add_funds_by_credit(_, _, _, _) do
    {:error, :invalid_amount}
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
            :cash -> :paid_by_cash
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

  def get_payment_method(user, amount, source? \\ nil) do
    cond do
      source? == "cash" ->
        :cash

      user && user.balance >= amount ->
        :balance

      true ->
        :charge
    end
  end

  def create_stripe_customer(email, stripe_token) do
    Stripe.Customer.create(
      %{email: email}
      |> Pipe.pass_unless(stripe_token, &Map.put(&1, :card, stripe_token))
    )
  end

  def get_stripe_customer(user) do
    Stripe.Customer.retrieve(user.stripe_customer_id)
  end

  def update_customer_card(user, stripe_token) do
    case user.stripe_customer_id do
      nil ->
        case create_stripe_customer(user.email, stripe_token) do
          {:ok, customer} ->
            user
            |> User.stripe_customer_changeset(%{stripe_customer_id: customer.id})
            |> Repo.update()

          error ->
            error
        end

      customer_id ->
        Stripe.Customer.update(customer_id, %{source: stripe_token})
    end
  end

  def create_deferred_stripe_account(email, business_name) do
    Stripe.Account.create(%{
      country: "US",
      type: "standard",
      email: email,
      business_name: business_name
    })
  end

  def get_transaction_email(%Transaction{} = transaction) do
    if transaction.user do
      transaction.user.email
    else
      transaction.email
    end
  end

  def create_stripe_charge(source_id, transaction) do
    case transaction.state do
      "pending" ->
        create_stripe_charge(
          source_id,
          transaction.user,
          get_transaction_email(transaction),
          transaction.total,
          transaction
        )

      _ ->
        {:error, :cannot_charge_non_pending_transaction}
    end
  end

  def create_stripe_charge(source_id, user?, email, total, school_context) do
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
        token_result =
          if user? do
            token =
              Stripe.Token.create(
                %{customer: user?.stripe_customer_id, card: source_id},
                connect_account: stripe_account.stripe_account_id
              )

            case token do
              {:ok, token} -> {:ok, token.id}
              error -> error
            end
          else
            {:ok, source_id}
          end

        case token_result do
          {:ok, token_id} ->
            Stripe.Charge.create(
              %{
                source: token_id,
                application_fee: application_fee_for_total(total),
                currency: "usd",
                receipt_email: email,
                amount: total
              },
              connect_account: stripe_account.stripe_account_id
            )

          error ->
            error
        end
    end
  end

  def application_fee_for_total(total) do
    trunc(total * 0.01)
  end
end
