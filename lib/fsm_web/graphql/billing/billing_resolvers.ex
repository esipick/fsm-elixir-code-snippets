defmodule FsmWeb.GraphQL.Billing.BillingResolvers do
  alias Fsm.Billing
  require Logger

  def get_all_transactions(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)
    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}

    if "admin" in roles or "dispatcher" in roles or "instructor" in roles do
      Billing.get_transactions(nil, page, per_page, sort_field, sort_order, filter, context)
    else
      Billing.get_transactions(id, page, per_page, sort_field, sort_order, filter, context)
    end
  end


  def get_transactions(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: user_id}}} = context
      ) do

    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    if "admin" in roles or "dispatcher" in roles or "instructor" in roles do
      Billing.get_transactions(nil, page, per_page, context)
    else
      Billing.get_transactions(user_id, page, per_page, context)
    end
  end

  def add_funds(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do

    IO.inspect("#{inspect args} requested by id(#{id}) on #{inspect DateTime.utc_now()}", label: "Add Funds Request: ")
    amount = Map.get(args, :amount)
    charge_payment_method = Map.get(args, :payment_method)
    description = Map.get(args, :description)
    requested_user_id = Map.get(args, :user_id)

    case charge_payment_method do
      :cash ->
        if "admin" in roles or "dispatcher" in roles do
          Billing.add_funds(%{user_id: id}, %{
            amount: amount,
            description: description,
            user_id: requested_user_id
          })
        else
          {:error, "Only 'admin' and 'dispatcher' can add funds using 'cash' payment method"}
        end

      _ ->
        %{roles: _roles, user: current_user} = Fsm.Accounts.get_user(id)

        if Map.get(current_user, :stripe_customer_id) not in [nil, "", " "] do
          Stripe.Customer.retrieve(current_user.stripe_customer_id)
          |> case do
               {:ok,
                 %Stripe.Customer{sources: %Stripe.List{data: [%Stripe.Card{id: stripe_customer, exp_month: exp_month, exp_year: exp_year} =card | _]},
                 default_source: source_id}
               } ->
                 with {:ok, parsed_amount} <- parse_amount(amount),
                      {:ok, expiry_date} <- Date.new(exp_year, exp_month, 28),
                      true <- Date.diff(expiry_date, Date.utc_today()) > 0
                  do

                   with acc_id <- Map.get(Billing.get_stripe_account_by_school_id(school_id), :stripe_account_id),
                        true <- acc_id != nil do

                   token_result =
                     if current_user do
                       token =
                         Stripe.Token.create(
                           %{customer: current_user.stripe_customer_id, card: source_id},
                           connect_account: acc_id
                         )

                       case token do
                         {:ok, token} -> {:ok, token.id}
                         error -> error
                       end
                     else
                       {:ok, source_id}
                     end
                 resp =
                   case token_result do
                     {:ok, token_id} ->
                       Stripe.Charge.create(
                         %{
                           source: token_id,
#                           application_fee: application_fee_for_total(parsed_amount),
                           currency: "usd",
                           receipt_email: current_user.email,
                           amount: parsed_amount
                         },
                         connect_account: acc_id
                       )

                     error ->
                       error
                   end

                   resp
                     |> case do
                        {:ok, %Stripe.Charge{status: "succeeded"}=resp} ->
                          Billing.add_funds(%{user_id: id}, %{
                            amount: amount,
                            description: description,
                            user_id: requested_user_id
                          })

                        {:error, %Stripe.Error{extra: %{message: message, param: param}}} ->
                          {:error, "Stripe Error in parameter '#{param}': #{message}"}

                        {:error, %Stripe.Error{extra: %{raw_error: %{"message" => message, "param" => param}}}} ->
                          {:error, "Stripe Error in parameter '#{param}': #{message}"}

                        {:error, %Stripe.Error{extra: %{message: message}}} ->
                          {:error, "Stripe Error: #{message}"}

                        {:error, %Stripe.Error{message: message}} ->
                          {:error, "Stripe Error: #{message}"}

                        {:error, error} ->
                          {:error, "Stripe Raw Error: #{error}"}


                        error ->
                          #Logger.info fn -> "Stripe Charge Error: #{inspect error}" end
                          {:error, "Something went wrong! Unable to add funds using card in user profile. Please update another card in profile or check amount and try again"}
                        end

                   else
                     nil -> {:error, "Stripe Account not added for this school."}
                     error ->
                       #Logger.info fn -> "Stripe Account for school Error: #{inspect error}" end
                       error
                   end

                 else
                 resp ->
                    if !resp do
                        {:error, "Card Expired! Please attach valid card in user profile"}
                    else
                        {:error, "Please attach valid amount to add funds"}
                    end

                 end
               error ->
                 #Logger.info fn -> "Stripe Error: #{inspect error}" end

                 {:error, "Please attach valid card in user profile"}
             end
          else
            {:error, "Invalid user's stripe customer id"}
          end
    end
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

  def fetch_card(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
    user_id = Map.get(args, :user_id)
    Billing.fetch_card(user_id)
  end

  def add_credit_card(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
    stripe_token = Map.get(args, :stripe_token)
    user_id = Map.get(args, :user_id)
    Billing.add_credit_card(stripe_token, user_id)
  end

  def create_invoice(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
        invoice = Map.get(args, :invoice)
        pay_off = Map.get(args, :pay_off)
        Billing.create_invoice(invoice, pay_off, school_id, id)
  end

  def update_invoice(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
        invoice = Map.get(args, :invoice)
        pay_off = Map.get(args, :pay_off)
        Billing.update_invoice(invoice, pay_off, school_id, id)
        |> case do
          {:error, message} ->
            {:error, message}
          data ->
            {:ok, data}
        end
  end

  def invoice_payment_option_enum(%{payment_option: payment_option}, _, _) do
    payment_options = %{
      0 => "BALANCE",
      1 => "CC",
      2 => "CASH",
      3 => "CHEQUE",
      4 => "VENMO",
      5 => "FUND"
    }
    matched_option = Map.get(payment_options, payment_option)
    {:ok, matched_option}
  end

  def invoice_payment_option_enum(_, _, _) do
    {:ok, ""}
  end
end
