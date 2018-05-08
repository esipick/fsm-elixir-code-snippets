defmodule FlightWeb.Admin.InvitationController do
  use FlightWeb, :controller

  alias Flight.Accounts

  def index(conn, %{"role" => role_slug}) do
    invitations = Accounts.invitations_with_role(role_slug)

    render(
      conn,
      "index.html",
      invitations: invitations,
      changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
      role: Accounts.role_for_slug(role_slug)
    )
  end

  def create(conn, %{"data" => %{"role_id" => role_id} = data}) do
    role = Accounts.get_role!(role_id)

    case Accounts.create_invitation(data) do
      {:ok, _invitation} ->
        redirect(conn, to: "/admin/invitations?role=#{role.slug}")

      {:error, changeset} ->
        invitations = Accounts.invitations_with_role(role.slug)
        render(conn, "index.html", invitations: invitations, changeset: changeset, role: role)
    end
  end
end
