defmodule FlightWeb.API.UserController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(FlightWeb.AuthenticateApiUser)
  plug(:get_user)

  def show(conn, _params) do
    render(conn, "show.json", user: conn.assigns.user)
  end

  def update(conn, params) do
    with {:ok, user} <- Accounts.update_user(conn.assigns.user, params["data"]) do
      render(conn, "show.json", user: user)
    end
  end

  defp get_user(conn, _) do
    assign(conn, :user, Accounts.get_user!(conn.params["id"]))
  end
end
