defmodule FlightWeb.Admin.ReportsController do
  use FlightWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def detail(conn, %{"from" => from, "to" => to, "type" => type}) do
    render(
      conn,
      "report_table.html",
      report_table: report(type, from, to, conn),
      from: from,
      to: to,
      report_type: type
    )
  end

  def detail(conn, params) do
    render(
      conn,
      "report_table.html",
      report_table: Flight.ReportTable.empty(),
      from: "",
      to: "",
      report_type: params["type"]
    )
  end

  defp report(type, from, to, school_context) do
    case type do
      "students" -> Flight.Reports.student_report(from, to, school_context)
      "instructors" -> Flight.Reports.instructor_report(from, to, school_context)
      _ -> Flight.ReportTable.empty()
    end
  end
end
