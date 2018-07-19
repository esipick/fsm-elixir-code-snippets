defmodule FlightWeb.Admin.SettingsView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers

  def stripe_authorize_url() do
    Stripe.Connect.OAuth.authorize_url(%{
      redirect_uri: Application.get_env(:flight, :web_base_url) <> "/admin/stripe_connect"
    })
  end
end
