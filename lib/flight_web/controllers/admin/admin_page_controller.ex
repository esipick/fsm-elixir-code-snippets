defmodule FlightWeb.Admin.PageController do
  use FlightWeb, :controller

  alias Flight.{Accounts}

  def dashboard(conn, _params) do
    student_count = Enum.count(Accounts.users_with_role(Accounts.Role.student()))
    instructor_count = Enum.count(Accounts.users_with_role(Accounts.Role.instructor()))
    renter_count = Enum.count(Accounts.users_with_role(Accounts.Role.renter()))
    aircraft_count = Flight.Repo.aggregate(Flight.Scheduling.Aircraft, :count, :id)

    expired_inspections =
      Flight.Scheduling.ExpiredInspection.inspections_for_aircrafts(
        Flight.Repo.all(Flight.Scheduling.Aircraft)
      )

    render(
      conn,
      "dashboard.html",
      student_count: student_count,
      instructor_count: instructor_count,
      renter_count: renter_count,
      aircraft_count: aircraft_count,
      expired_inspections: expired_inspections
    )
  end
end
