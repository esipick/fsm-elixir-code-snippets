defmodule FlightWeb.Student.ScheduleController do
  use FlightWeb, :controller

  alias Flight.Accounts.Role

  def index(conn, _) do
    current_user = conn.assigns.current_user
    renters = [current_user]
    instructors = Flight.Accounts.users_with_roles([Role.instructor()], conn)
    aircrafts = Flight.Scheduling.visible_air_assets(conn)

    render(conn, "index.html",
      renters: renters,
      instructors: instructors,
      aircrafts: aircrafts,
      user_id: current_user.id
    )
  end

  def show(conn, _) do
    render(conn, "show.html")
  end
end
