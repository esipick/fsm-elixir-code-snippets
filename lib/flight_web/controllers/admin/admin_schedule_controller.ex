defmodule FlightWeb.Admin.ScheduleController do
  use FlightWeb, :controller

  alias Flight.Accounts.Role

  def index(conn, _) do
    renters = Flight.Accounts.users_with_roles([Role.student(), Role.renter()], conn)
    instructors = Flight.Accounts.users_with_roles([Role.instructor()], conn)
    aircrafts = Flight.Scheduling.visible_aircrafts(conn)
    simulators = Flight.Scheduling.visible_simulators(conn)
    rooms = Flight.SchoolAssets.visible_rooms(conn)

    render(conn, "index.html", renters: renters, instructors: instructors, aircrafts: aircrafts, simulators: simulators, rooms: rooms)
  end

  def show(conn, _) do
    render(conn, "show.html")
  end
end
