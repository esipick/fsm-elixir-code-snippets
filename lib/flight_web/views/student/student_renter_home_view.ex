defmodule FlightWeb.Student.HomeView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers
  alias Flight.Accounts
  alias Flight.Aircrafts
  alias Fsm.Aircrafts.ExpiredInspection
end
