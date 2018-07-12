defmodule FlightWeb.Admin.PageController do
  use FlightWeb, :controller

  alias Flight.{Accounts}

  def dashboard(conn, _params) do
    student_count = Enum.count(Accounts.users_with_role(Accounts.Role.student(), conn))
    instructor_count = Enum.count(Accounts.users_with_role(Accounts.Role.instructor(), conn))
    renter_count = Enum.count(Accounts.users_with_role(Accounts.Role.renter(), conn))
    aircrafts = Flight.Scheduling.visible_aircrafts(conn)

    expired_inspections = Flight.Scheduling.ExpiredInspection.inspections_for_aircrafts(aircrafts)

    pending_transactions =
      Flight.Billing.get_filtered_transactions(%{"state" => "pending"}, conn)
      |> Flight.Repo.preload([:user])

    render(
      conn,
      "dashboard.html",
      student_count: student_count,
      instructor_count: instructor_count,
      renter_count: renter_count,
      aircraft_count: Enum.count(aircrafts),
      expired_inspections: expired_inspections,
      pending_transactions: pending_transactions
    )
  end

  def schools(conn, _params) do
    render(conn, "schools.html")
  end
end
