defmodule Flight.StripeSinglePayment do
    alias Flight.Billing

    def get_stripe_session(nil, _info), do: {:error, "School id not identified."}
    def get_stripe_session(school_id, info) do
        # get stripe account id.
        with %{stripe_account_id: acc_id} <- Billing.get_stripe_account_by_school_id(school_id),
            {:ok, %{id: id}} <- create_session(acc_id, info) do
                pub_key = Application.get_env(:flight, :stripe_publishable_key)

                {:ok, %{stripe_session_id: id, stripe_account_id: acc_id, pub_key: pub_key}}

        else
            nil -> {:error, "Stripe Account not added for this school."}
            {:error, error} -> 
                {:error, "Unable to create stripe session, Please try again later."}

        end    
    end

    def create_session(account_id, %{cancel_url: cancel_url, success_url: success_url}) do
        params = %{
            "mode" => "payment",
            "payment_method_types" => ["card"],
            "line_items" => [%{
                "name" => "Flight Hours",
                "currency" => "usd",
                "amount" => 2000,
                "quantity" => 1
                }],
            "success_url" => success_url,
            "cancel_url" => cancel_url
        }

        Stripe.Session.create(params, [{"Stripe-Account", account_id}])
    end
end