defmodule FlightWeb.Instructor.ScheduleController do
  use FlightWeb, :controller

  alias Flight.Accounts.Role

  def index(conn, _) do
    renters = Flight.Accounts.users_with_roles([Role.student(), Role.renter()], conn)
    instructors = [conn.assigns.current_user]
    aircrafts = Flight.Scheduling.visible_aircrafts(conn)

    # TODO: shared view with schedule
    render(conn, "index.html", renters: renters, instructors: instructors, aircrafts: aircrafts)
  end

  def show(conn, _) do
    render(conn, "show.html")
  end
end
