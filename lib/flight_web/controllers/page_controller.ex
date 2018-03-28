defmodule FlightWeb.PageController do
  use FlightWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
