defmodule FlightWeb.PageController do
  use FlightWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: "/login")
  end
end
