defmodule FlightWeb.API.AircraftController do
  use FlightWeb, :controller

  alias Flight.Scheduling
  alias Flight.Auth.Permission

  plug(:authorize_view_all when action in [:autocomplete])

  def index(conn, _) do
    aircrafts =
      Scheduling.visible_aircrafts(conn)
      |> Flight.Repo.preload(:inspections)

    render(conn, "index.json", aircrafts: aircrafts)
  end

  def show(conn, %{"id" => id}) do
    aircraft =
      Scheduling.get_visible_aircraft(id, conn)
      |> Flight.Repo.preload(:inspections)

    render(conn, "show.json", aircraft: aircraft)
  end

  def autocomplete(conn, %{"search" => search_term} = _params) do
    aircrafts = Flight.Scheduling.visible_aircraft_query(conn, search_term) |> Flight.Repo.all()

    render(conn, "autocomplete.json", aircrafts: aircrafts)
  end

  def authorize_view_all(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:aircraft, :view, :all)])
  end
end
