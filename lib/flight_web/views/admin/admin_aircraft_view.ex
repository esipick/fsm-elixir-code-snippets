defmodule FlightWeb.Admin.AircraftView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers
  import Scrivener.HTML

  def show_for_superadmin(%{assigns: %{current_user: current_user}}, do: block) do
    if Flight.Accounts.is_superadmin?(current_user) do
      block
    end
  end
end
