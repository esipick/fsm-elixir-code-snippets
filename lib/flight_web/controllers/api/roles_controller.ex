defmodule FlightWeb.API.RolesController do
  use FlightWeb, :controller

  alias Flight.Auth.Permission
  import Flight.Auth.Authorization

  plug(:authorize_view when action in [:index])

  def index(conn, _) do
    roles = Flight.Accounts.Role |> Flight.Repo.all()
    user = conn.assigns.current_user

    visible_roles = if user_can?(user, [Permission.new(:admins, :modify, :all)]) do
      roles
    else
      Enum.filter(roles, fn r -> r.slug != "admin" end)
    end

    render(conn, "index.json", roles: visible_roles)
  end

  def authorize_view(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:role, :view, :all)])
  end
end
