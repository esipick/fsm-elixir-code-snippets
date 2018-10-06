defmodule FlightWeb.PageController do
  use FlightWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: "/admin/login")
  end
end
