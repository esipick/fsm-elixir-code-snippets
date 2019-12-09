defmodule FlightWeb.API.RolesController do
  use FlightWeb, :controller

  alias Flight.Auth.Permission
  alias Flight.Accounts.Role
  import Flight.Auth.Authorization

  plug(:authorize_view when action in [:index])

  def index(conn, _) do
    render(conn, "index.json", roles: visible_roles(conn))
  end

  def authorize_view(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:role, :view, :all)])
  end

  defp visible_roles(conn) do
    user = conn.assigns.current_user
    roles = Role |> Flight.Repo.all()

    if user_can?(user, [Permission.new(:admins, :modify, :all)]) do
      roles
    else
      Enum.filter(roles, fn r -> !(r.slug in ["admin", "dispatcher"]) end)
    end
  end
end
