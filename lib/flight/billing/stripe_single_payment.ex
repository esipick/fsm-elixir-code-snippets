defmodule Flight.StripeSinglePayment do
    alias Flight.Billing

    def get_stripe_session(_invoice, nil), do: {:error, "School id not identified."}
    def get_stripe_session(invoice, school_id) do
        info = %{
            "cancel_url" => base_url() <> "/billing/invoices/#{invoice.id}/edit",
            "success_url" => base_url() <> "/billing/invoices/#{invoice.id}",
            "line_items" => map_line_items(invoice.line_items)
        }
        
        with %{stripe_account_id: acc_id} <- Billing.get_stripe_account_by_school_id(school_id),
            {:ok, %{id: id}} <- create_session(acc_id, info) do
                pub_key = FlightWeb.StripeHelper.stripe_key()
                {:ok, %{session_id: id, connect_account: "acct_1HEy8fHf8cmTIKS1", pub_key: pub_key}}

        else
            nil -> {:error, "Stripe Account not added for this school."}
            error -> error
        end    
    end

    def create_session(account_id, info) do
        %{
            "mode" => "payment",
            "payment_method_types" => ["card"],
            "payment_intent_data" => %{
                "application_fee_amount" => 123,
            }
        }
        |> Map.merge(info)
        |> Stripe.Session.create([connect_account: "acct_1HEy8fHf8cmTIKS1"])
    end

    defp map_line_items(nil), do: []
    defp map_line_items(line_items) do
        Enum.map(line_items, fn item ->
            %{
                "quantity" => round(item.quantity),
                "currency" => "usd",
                "amount" => item.rate,
                "name" => item.description
            }
        end)
    end

    defp base_url() do 
        FlightWeb.Endpoint.url()
    end
    
end