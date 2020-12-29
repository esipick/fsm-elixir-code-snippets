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
        Billing.add_funds(%{user_id: id}, %{
          amount: amount,
          description: description,
          user_id: requested_user_id
        })

      _ ->
        %{roles: _roles, user: current_user} = Fsm.Accounts.get_user(id)

          Stripe.Customer.retrieve(current_user.stripe_customer_id)
          |> case do
               {:ok, %Stripe.Customer{sources: %Stripe.List{data: [%Stripe.Card{id: stripe_customer, exp_month: exp_month, exp_year: exp_year} =card | _]}}} ->
                 with {:ok, parsed_amount} <- parse_amount(amount),
                      {:ok, expiry_date} <- Date.new(exp_year, exp_month, 28),
                      true <- Date.diff(expiry_date, Date.utc_today()) > 0
                  do
                   Stripe.PaymentIntent.create(%{
                     amount: parsed_amount,
                     currency: "USD",
                     customer: current_user.stripe_customer_id,
                     payment_method_types: ["card"],
                     off_session: true,
                     confirm: true
                   })
                   |> case do
                      {:ok, %Stripe.PaymentIntent{status: "succeeded"}=resp} ->
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


                      _ ->
                        {:error, "Something went wrong! Unable to add funds using card in user profile. Please update another card in profile or check amount and try again"}
                      end

                 else
                 resp ->
                    if !resp do
                        {:error, "Card Expired! Please attach valid card in user profile"}
                    else
                        {:error, "Please attach valid amount to add funds"}
                    end

                 end
               _ ->
                 {:error, "Please attach valid card in user profile"}
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
    {:ok, %{
        0 => "BALANCE",
        1 => "CC",
        2 => "CASH",
        3 => "CHEQUE",
        4 => "VENMO"
      }
      |> Map.get(payment_option)}
  end

  def invoice_payment_option_enum(_, _, _) do
    {:ok, ""}
  end
end
