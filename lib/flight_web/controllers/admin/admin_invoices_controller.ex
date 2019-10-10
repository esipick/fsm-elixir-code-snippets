defmodule FlightWeb.Admin.InvoicesController do
  use FlightWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end
end
