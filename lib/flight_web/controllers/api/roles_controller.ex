defmodule FlightWeb.API.RolesController do
  use FlightWeb, :controller

  alias Flight.Auth.Permission
  alias Flight.Accounts.Role
  import Flight.Auth.Authorization

  plug(:authorize_view when action in [:index])

  def index(conn, params) do
    render(conn, "index.json", roles: visible_roles(conn, params["demo_only"]))
  end

  def authorize_view(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:role, :view, :all)])
  end

  defp visible_roles(conn, demo_only) do
    if demo_only == "true" do
      [Flight.Repo.get_by(Role, slug: "renter")]
    else
      check_permissions(conn)
    end
  end

  defp check_permissions(conn) do
    user = conn.assigns.current_user
    roles = Role |> Flight.Repo.all()

    if user_can?(user, [Permission.new(:admins, :modify, :all)]) do
      roles
    else
      Enum.filter(roles, fn r -> !(r.slug in ["admin", "dispatcher"]) end)
    end
  end
end
