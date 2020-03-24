defmodule Flight.Billing.Stripe do
  import Stripe.Request

  def create_ephemeral_key(user, api_version) do
    new_request([], %{"Stripe-Version" => api_version})
    |> put_endpoint("ephemeral_keys")
    |> put_params(%{customer: user.stripe_customer_id})
    |> put_method(:post)
    |> make_request()
  end
end
