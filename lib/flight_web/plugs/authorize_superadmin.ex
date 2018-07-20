defmodule FlightWeb.AuthorizeSuperadmin do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts \\ []) do
    if Flight.Accounts.is_superadmin?(conn.assigns.current_user) do
      conn
    else
      conn
      |> Phoenix.Controller.redirect(to: "/admin/dashboard")
      |> halt()
    end
  end
end
