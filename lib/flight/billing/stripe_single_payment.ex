defmodule Flight.StripeSinglePayment do
    alias Flight.Billing
    require Logger
    def get_stripe_session(_invoice, nil), do: {:error, "School id not identified."}
    def get_stripe_session(invoice, school_id) do
        {line_items, total_amount} = map_line_items(invoice.line_items)

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
        {_line_items, total_amount} = map_line_items(invoice.line_items)

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

    defp map_line_items(nil), do: []
    defp map_line_items(line_items) do
        Enum.reduce(line_items, {[], 0}, fn(item, acc) ->
            {line_items, total} = acc

            total = total + (round(item.quantity) * item.rate / 10)

            item = 
                %{
                    "quantity" => round(item.quantity),
                    "currency" => "usd",
                    "amount" => item.rate,
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
    
end