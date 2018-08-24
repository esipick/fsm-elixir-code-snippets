defmodule FlightWeb.Admin.ReportsController do
  use FlightWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end
  
  def students(conn, _) do
    render(conn, "students.html")
  end
  
  def renters(conn, _) do
    render(conn, "renters.html")
  end
  
  def instructors(conn, _) do
    render(conn, "instructors.html")
  end
  
  def aircraft(conn, _) do
    render(conn, "aircraft.html")
  end


end

