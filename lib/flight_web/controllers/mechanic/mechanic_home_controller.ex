defmodule FlightWeb.Mechanic.HomeController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Repo, Scheduling}
  alias Fsm.Squawks
  def index(%{assigns: %{current_user: current_user}} = conn, _) do
    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), conn)
    aircrafts = Scheduling.visible_air_assets(conn)

    user = Repo.preload(current_user, [:roles, :aircrafts, :instructors, :main_instructor])
    options = %{"mechanic_user_id" => user.id, "sort_order" => "asc"}
    appointments =
      Scheduling.get_appointments(options, conn)
      |> Repo.preload([:aircraft])


    expired_inspections = Fsm.Aircrafts.ExpiredInspection.inspections_for_aircrafts(aircrafts)

    render(
      conn,
      "index.html",
      user: user,
      instructor_count: instructor_count,
      aircraft_count: Enum.count(aircrafts),
      appointments: appointments,
      expired_inspections: expired_inspections
    )
  end
end
