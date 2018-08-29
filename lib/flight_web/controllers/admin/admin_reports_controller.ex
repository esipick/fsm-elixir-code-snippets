defmodule FlightWeb.Admin.ReportsController do
  use FlightWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def detail(conn, %{"from" => from, "to" => to, "type" => type}) do
    render(
      conn,
      "report_table.html",
      report_table: Flight.Reports.report(type, from, to, conn),
      from: from,
      to: to,
      report_type: type
    )
  end

  def detail(conn, %{"type" => type}) do
    school = Flight.SchoolScope.get_school(conn)

    now = Timex.now(school.timezone)

    from =
      now
      |> Timex.beginning_of_month()
      |> Flight.Reports.format_date()

    to =
      now
      |> Timex.end_of_month()
      |> Flight.Reports.format_date()

    redirect(conn, to: "/admin/reports/detail?type=#{type}&from=#{from}&to=#{to}")
  end
end
