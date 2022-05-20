defmodule FlightWeb.Dispatcher.HomeController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Repo, Scheduling}
  alias Fsm.Squawks

  def index(%{assigns: %{current_user: current_user}} = conn, _) do
    student_count = Accounts.get_user_count(Accounts.Role.student(), conn)
    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), conn)
    renter_count = Accounts.get_user_count(Accounts.Role.renter(), conn)
    aircrafts = Scheduling.visible_air_assets(conn)

    squawks = Fsm.Squawks.get_squawks(aircrafts)

    render(
      conn,
      "index.html",
      squawks: squawks,
      student_count: student_count,
      instructor_count: instructor_count,
      renter_count: renter_count,
      aircraft_count: Enum.count(aircrafts)
    )
  end
end
