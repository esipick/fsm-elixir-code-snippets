defmodule FlightWeb.API.AircraftController do
  use FlightWeb, :controller

  alias Flight.Scheduling

  def index(conn, _) do
    aircrafts = Scheduling.visible_aircrafts()

    render(conn, "index.json", aircrafts: aircrafts)
  end
end
