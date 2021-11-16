defmodule Flight.StripeSinglePayment do
    alias Flight.Billing
    require Logger
    def get_stripe_session(_invoice, nil), do: {:error, "School id not identified."}
    def get_stripe_session(invoice, school_id) do
        {line_items, total_amount} = map_line_items(invoice.line_items, invoice.tax_rate)

        info = %{
            "cancel_url" => base_url() <> "/billing/invoices/#{invoice.id}/edit",
            "success_url" => base_url() <> "/billing/checkout_success?session_id={CHECKOUT_SESSION_ID}",
            "line_items" => line_items,
            "payment_intent_data" => %{
                "application_fee_amount" => application_fee(total_amount),
            }
        }
        Logger.info fn -> "Url info: #{inspect info}" end
        
        with %{stripe_account_id: acc_id} <- Billing.get_stripe_account_by_school_id(school_id),
            {:ok, %{id: id}} <- create_session(acc_id, info) do
                pub_key = FlightWeb.StripeHelper.stripe_key()
                {:ok, %{session_id: id, connect_account: acc_id, pub_key: pub_key}}

        else
            nil -> {:error, "Stripe Account not added for this school."}
            error -> error
        end    
    end

    def charge_stripe_token(_invoice, nil), do: {:error, "School id not identified."}
    def charge_stripe_token(invoice, school_id) do
        {line_items, total_amount} = map_line_items(invoice.line_items, invoice.tax_rate)

        info =
        %{
            source: Map.get(invoice, :stripe_token),
            application_fee: application_fee(total_amount),
            currency: "usd",
            amount: round(total_amount)
        }
        Logger.info fn -> "Param info: #{inspect info}" end

        with %{stripe_account_id: acc_id} <- Billing.get_stripe_account_by_school_id(school_id),
            {:ok, %{id: id}} <- Stripe.Charge.create(info, connect_account: acc_id) do
                pub_key = FlightWeb.StripeHelper.stripe_key()
                {:ok, %{session_id: id, connect_account: acc_id, pub_key: pub_key}}

        else
            nil -> {:error, "Stripe Account not added for this school."}
            error -> error
        end
    end

    def create_session(account_id, info) do
        %{
            "mode" => "payment",
            "payment_method_types" => ["card"]
        }
        |> Map.merge(info)
        |> Stripe.Session.create([connect_account: account_id])
    end

    def get_payment_intent_secret(_invoice, nil), do: {:error, "School id not identified."}
    def get_payment_intent_secret(invoice, school_id) do
        {_line_items, total_amount} = map_line_items(invoice.line_items, invoice.tax_rate)

        with %{stripe_account_id: acc_id} <- Billing.get_stripe_account_by_school_id(school_id),
            {:ok, %{id: id, client_secret: secret}} <- create_payment_intent(acc_id, total_amount) do
                pub_key = FlightWeb.StripeHelper.stripe_key()

                {:ok, %{intent_id: id, session_id: secret, connect_account: acc_id, pub_key: pub_key}}

        else
            nil -> {:error, "Stripe Account not added for this school."}
            error -> error
        end
    end

    defp create_payment_intent(account_id, amount) do
        info = %{
            "payment_method_types" => ["card"],
            "amount" => round(amount),
            "currency" => "usd",
            "application_fee_amount" => application_fee(amount)
        }

        Stripe.PaymentIntent.create(info, [connect_account: account_id])
    end

    defp map_line_items(nil, _tax_rate), do: []
    defp map_line_items(line_items, tax_rate) do
        line_items = Enum.filter(line_items, &(&1.rate > 0 && &1.quantity > 0))

        Enum.reduce(line_items, {[], 0}, fn(item, acc) ->
            {line_items, total} = acc
            rate = item.quantity * item.rate
            quantity = item.quantity
            

            {total, rate } =
                if item.taxable do
                    tax = escape_scientific_notation(rate * tax_rate) / 100

                    rate = rate + tax
                    total = total + rate

                    {total, rate / quantity}

                else
                    total = total + (quantity * item.rate)
                    {total, item.rate}
                end

            item = 
                %{
                    "quantity" => quantity,
                    "currency" => "usd",
                    "amount" => escape_scientific_notation(rate),
                    "name" => item.description
                }

            {[item | line_items], total}
        end)
    end

    defp application_fee(amount) do
        fee = Flight.Billing.application_fee_for_total(amount) 
        if fee > 1, do: fee, else: 1
    end

    defp base_url() do
      Application.get_env(:flight, :web_base_url)
    end

    defp escape_scientific_notation(value) do

        with {value, _} <- Float.parse("#{value}"),
            value <- :erlang.float_to_binary(value, decimals: 2),
            {value, _} <- Integer.parse("#{value}") do
            value
        else
            _ -> value
        end
    end
end
