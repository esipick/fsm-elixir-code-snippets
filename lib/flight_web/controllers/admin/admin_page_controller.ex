defmodule FlightWeb.Admin.PageController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Billing, Scheduling}

  def dashboard(conn, _params) do
    student_count = Accounts.get_user_count(Accounts.Role.student(), conn)
    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), conn)
    renter_count = Accounts.get_user_count(Accounts.Role.renter(), conn)
    aircrafts = Scheduling.visible_air_assets(conn)

    fsm_income = Billing.platform_income()

    expired_inspections = Fsm.Aircrafts.ExpiredInspection.inspections_for_aircrafts(aircrafts)

    pending_transactions =
      Flight.Billing.get_filtered_transactions(%{"state" => "pending"}, conn)
      |> Flight.Repo.preload([:user])

    total_pending =
      pending_transactions
      |> Enum.map(& &1.total)
      |> Enum.sum()

    render(
      conn,
      "dashboard.html",
      student_count: student_count,
      instructor_count: instructor_count,
      renter_count: renter_count,
      aircraft_count: Enum.count(aircrafts),
      expired_inspections: expired_inspections,
      pending_transactions: pending_transactions,
      fsm_income: fsm_income,
      total_pending: total_pending
    )
  end

  def root(conn, _) do
    redirect(conn, to: "/admin/dashboard")
  end

  def schools(conn, _params) do
    render(conn, "schools.html")
  end
end
