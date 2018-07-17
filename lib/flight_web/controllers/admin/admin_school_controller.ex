defmodule FlightWeb.Admin.SchoolController do
  use FlightWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

def show(conn, _) do
    render(conn, "show.html")
  end
end
