defmodule FlightWeb.Admin.InvitationController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(:get_invitation when action in [:resend])

  def index(conn, %{"role" => role_slug}) do
    invitations = Accounts.visible_invitations_with_role(role_slug)

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
        invitations = Accounts.visible_invitations_with_role(role.slug)
        render(conn, "index.html", invitations: invitations, changeset: changeset, role: role)
    end
  end

  def resend(conn, _params) do
    Accounts.send_invitation_email(conn.assigns.invitation)

    role = Accounts.get_role(conn.assigns.invitation.role_id)

    conn
    |> put_flash(
      :success,
      "Successfully sent invitation email to #{conn.assigns.invitation.email}"
    )
    |> redirect(to: "/admin/invitations?role=#{role.slug}")
  end

  defp get_invitation(conn, _) do
    invitation = Accounts.get_invitation(conn.params["id"] || conn.params["invitation_id"])

    if invitation do
      assign(conn, :invitation, invitation)
    else
      conn
      |> resp(404, "")
      |> halt()
    end
  end
end
