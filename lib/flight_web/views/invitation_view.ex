defmodule FlightWeb.InvitationView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers

  def stripe_key() do
    Application.get_env(:flight, :stripe_publishable_key)
  end

  def platform_fee_amount() do
    currency(Application.get_env(:flight, :platform_fee_amount), :short)
  end

  def needs_card?(invitation) do
    invitation.role.slug in ["student", "renter"]
  end

  def will_charge_platform_fee?(invitation) do
    invitation.role.slug in ["student"]
  end
end
