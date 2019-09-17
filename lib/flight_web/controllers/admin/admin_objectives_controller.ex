defmodule FlightWeb.Admin.ObjectivesController do
  use FlightWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def edit(conn, _) do
    render(conn, "edit.html")
  end
end
