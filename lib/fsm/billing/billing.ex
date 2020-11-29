defmodule Fsm.Billing do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Fsm.Billing.BillingQueries
  alias Fsm.Billing.Transaction
  alias Fsm.Billing.TransactionLineItem
  alias Fsm.Accounts 
  alias Fsm.SchoolScope
  alias Fsm.Accounts.User
  alias Fsm.Billing.Invoice
  alias Fsm.Billing.CreateInvoice
  alias Fsm.Billing.UpdateInvoice
  alias Fsm.Billing.PaymentError
  require Logger

  def create_invoice(invoice_params, pay_off, school_id, user_id) do
    %Invoice{}
    |> Invoice.payment_options_changeset(invoice_params)
    |> case do
      %Ecto.Changeset{valid?: true} ->
          CreateInvoice.run(invoice_params, pay_off, school_id, user_id)
      
      changeset -> {:error, changeset}
    end
  end

  def update_invoice(invoice_params, pay_off, school_id, user_id) do
    invoice_params = Map.put(invoice_params, :is_visible, true)
    case UpdateInvoice.run(invoice_params, pay_off, school_id, user_id) do
      {:ok, invoice} ->
        session_info = Map.take(invoice, [:session_id, :connect_account, :pub_key])
        
        invoice =
          Repo.get(Invoice, invoice.id)
          |> Repo.preload([:line_items, :user, :school, :appointment], force: true)
          |> Map.merge(session_info)

       {:error, %Ecto.Changeset{errors: [invoice: {message, []}]} = changeset} ->

        {:error, :update_error}

       {:error, %Ecto.Changeset{} = changeset} ->

        {:error, :update_error}

       {:error, %Stripe.Error{} = error} ->
        # status = Map.get(error.extra, :http_status) || 422

        # {{conn
        # |> put_status(status)
        # |> json(%{stripe_error: StripeHelper.human_error(error)})}}
        {:error, StripeHelper.human_error(error)}

      {:error, %PaymentError{} = error} ->

        # conn
        # |> put_status(400)
        # |> json(%{stripe_error: StripeHelper.human_error(error.message)})
        {:error, StripeHelper.human_error(error.message)}

      {:error, msg} ->
        message = 
        if(is_map(msg)) do
          Map.get(msg, :message)
        else
          msg
        end
        {:error, message}
        # conn
        # |> put_status(422)
        # |> json(%{error: %{message: msg}})
    end
  end

  def get_transactions(user_id, page, per_page, sort_field, sort_order, filter, context) do
    BillingQueries.list_bills_query(
      user_id,
      page,
      per_page,
      sort_field,
      sort_order,
      filter,
      context
    )
    |> Repo.all
    |> case do
      nil ->
        {:ok, nil}

      data ->
        data =
          Enum.map(data, fn i ->
            transactions =
              Map.get(i, :transactions)
              |> Enum.reject(fn transaction -> Map.get(transaction, "id") == nil end)
              |> Enum.map(fn transaction ->
                %{
                  id: Map.get(transaction, "id"),
                  total: Map.get(transaction, "total"),
                  paid_by_balance: Map.get(transaction, "paid_by_balance"),
                  paid_by_charge: Map.get(transaction, "paid_by_charge"),
                  stripe_charge_id: Map.get(transaction, "stripe_charge_id"),
                  state: Map.get(transaction, "state"),
                  creator_user_id: Map.get(transaction, "creator_user_id"),
                  completed_at: Map.get(transaction, "completed_at"),
                  type: Map.get(transaction, "type"),
                  first_name: Map.get(transaction, "first_name"),
                  last_name: Map.get(transaction, "last_name"),
                  email: Map.get(transaction, "email"),
                  paid_by_cash: Map.get(transaction, "paid_by_cash"),
                  paid_by_check: Map.get(transaction, "paid_by_check"),
                  paid_by_venmo: Map.get(transaction, "paid_by_venmo"),
                  payment_option: Map.get(transaction, "payment_option")
                }
              end)

            %{
              id: i.id,
              date: i.date,
              total: i.total,
              tax_rate: i.tax_rate,
              total_tax: i.total_tax,
              total_amount_due: i.total_amount_due,
              status: i.status,
              payment_option: i.payment_option,
              payer_name: payer_name(i),
              demo: i.demo,
              archived: i.archived,
              is_visible: i.is_visible,
              archived_at: i.archived_at,
              appointment_updated_at: i.appointment_updated_at,
              appointment_id: i.appointment_id,
              # aircraft_info: i.aircraft_info,
              session_id: i.session_id,
              transactions: transactions,
              inserted_at: i.inserted_at
            }
          end)

        {:ok, %{invoices: data, page: page}}
    end
  end

  defp payer_name(invoice) do
    user = Map.get(invoice, :user)

    Map.get(invoice, :payer_name)
    |> payer_name(user)
  end

  def create_stripe_customer(email, stripe_token) do
    Stripe.Customer.create(
      %{email: email}
      |> Pipe.pass_unless(stripe_token, &Map.put(&1, :card, stripe_token))
    )
  end

  def add_credit_card(stripe_token, user_id) do
    %{roles: _roles, user: user} = Accounts.get_user(user_id)
    case user.stripe_customer_id do
      nil ->
        case create_stripe_customer(user.email, stripe_token) do
          {:ok, customer} ->
            user
            |> User.stripe_customer_changeset(%{stripe_customer_id: customer.id})
            |> Repo.update()
            |> case do
              {:ok, _} ->
                {:ok, :success}
              _->
                {:error, :failed}
            end

          error ->
            {:error, :faild}
        end

      customer_id ->
        Stripe.Customer.update(customer_id, %{source: stripe_token})
        |> case do
          {:ok, _customer} ->
            {:ok, :success}
          _-> 
            {:error, :failed}
        end
    end
  end

  defp payer_name(payer_name, user) when payer_name == nil do
    user_first_name = Map.get(user, :first_name)
    user_last_name = Map.get(user, :last_name)
    user_first_name <> " " <> user_last_name
  end

  defp payer_name(payer_name, _user) when payer_name != nil do
    payer_name
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

  def add_funds_by_credit(user, creator_user, amount, description)
      when is_integer(amount) and (amount > 0 or amount < 0) do
    {transaction_type, line_item_type} =
      if amount > 0 do
        {"credit", "add_funds"}
      else
        {"debit", "remove_funds"}
      end

    {:ok, result} = Repo.transaction(fn ->
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
          |> Pipe.pass_unless(
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
      # |> SchoolScope.scope_query(school_context)
      |> where([t], t.state != "canceled")
      |> where([t], not is_nil(t.user_id))
      |> Pipe.pass_unless(params["state"], &where(&1, [t], t.state == ^params["state"]))
      |> Pipe.pass_unless(params["user_id"], &where(&1, [t], t.user_id == ^params["user_id"]))
      |> Pipe.pass_unless(user_ids, &where(&1, [t], t.user_id in ^user_ids))
      |> Pipe.pass_unless(total, &where(&1, [t], fragment("?::text ILIKE ?", t.total, ^"%#{total}%")))
      |> Pipe.pass_unless(
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

  def get_stripe_customer(user) do
    Stripe.Customer.retrieve(user.stripe_customer_id)
  end

  def get_transaction_email(%Transaction{} = transaction) do
    if transaction.user do
      transaction.user.email
    else
      transaction.email
    end
  end

  def application_fee_for_total(total) do
    trunc(total * 0.01)
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
        {:error, %{message: "You are not set up to receive charges"}}

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


  def add_funds(%{user_id: current_user_id}, %{amount: amount, description: description, user_id: requested_user_id}) do

    with %{roles: _roles, user: current_user} <- Accounts.get_user(current_user_id),
         %{roles: _roles, user: requested_user} <- Accounts.get_user(requested_user_id),
         {:ok, cent_amount} <- parse_amount(amount),
         {:ok, {user, transaction}} <-
           add_funds_by_credit(
             requested_user,
             current_user,
             cent_amount,
             description
           ) do

      approve_transactions_within_balance(user)

      {:ok, :success}
    else
      {:error, :invalid} ->
        {:error, :invalid}

      {:error, :negative_balance} ->
        {:error, :negative_balance} 
      _->
        {:error, :user_not_found} 
    end
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

  def fetch_card(user_id) do
    with %{roles: _roles, user: user} <- Accounts.get_user(user_id) do
      if user.stripe_customer_id do
        case Stripe.Customer.retrieve(user.stripe_customer_id) do
          {:ok, customer} ->
            source = Enum.find(customer.sources.data, fn s -> s.id == customer.default_source end)
            {:ok, source}
          _ ->
            {:error, :not_found}
        end
      end
    else
      _->
        {:error, :failed}
    end
  end

  def get_invoice(invoice_id) do
    invoice = Repo.get(Invoice, invoice_id) 
    |> Repo.preload(:line_items) 
    |> Repo.preload(:user)
    |> Repo.preload(:appointment)
  end
  
end
