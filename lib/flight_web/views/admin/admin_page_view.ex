defmodule FlightWeb.Admin.PageView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers

  def can_see_fsm_panels?(user) do
    Flight.Accounts.is_superadmin?(user)
  end
end
