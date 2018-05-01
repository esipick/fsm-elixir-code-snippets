defmodule FlightWeb.Admin.PageController do
  use FlightWeb, :controller

  def dashboard(conn, _params) do
    render(conn, "dashboard.html")
  end
end
