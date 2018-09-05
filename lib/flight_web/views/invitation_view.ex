defmodule FlightWeb.InvitationView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers

  def stripe_key() do
    Application.get_env(:flight, :stripe_publishable_key)
  end
end
