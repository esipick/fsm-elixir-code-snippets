defmodule FlightWeb.Admin.SettingsView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers

  def stripe_authorize_url() do
    Stripe.Connect.OAuth.authorize_url(%{
      redirect_uri: Application.get_env(:flight, :web_base_url) <> "/admin/stripe_connect"
    })
  end

  def stripe_activation_url(stripe_account) do
    "https://dashboard.stripe.com/account/activate?client_id=#{
      Application.get_env(:stripity_stripe, :connect_client_id)
    }&user_id=#{stripe_account.stripe_account_id}"
  end
end
