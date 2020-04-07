defmodule FlightWeb.Admin.InvitationController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(:get_invitation when action in [:resend, :delete])

  def index(conn, %{"role" => role_slug}) do
    invitations = Accounts.visible_invitations_with_role(role_slug, conn)

    render(
      conn,
      "index.html",
      invitations: invitations,
      changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
      request_path: invite_request_path(conn),
      role: Accounts.role_for_slug(role_slug)
    )
  end

  def create(conn, %{"data" => %{"role_id" => role_id} = data}) do
    role = Accounts.get_role!(role_id)

    case Accounts.create_invitation(data, conn) do
      {:ok, invitation} ->
        conn
        |> put_flash(
          :success,
          "Successfully sent invitation. Please have #{invitation.first_name} check their email to complete the sign up process."
        )
        |> redirect(to: "/admin/invitations?role=#{role.slug}")

      {:error, changeset} ->
        invitations = Accounts.visible_invitations_with_role(role.slug, conn)

        render(conn, "index.html",
          invitations: invitations,
          changeset: changeset,
          request_path: invite_request_path(conn),
          role: role
        )
    end
  end

  def delete(conn, _params) do
    Accounts.delete_invitation!(conn.assigns.invitation)

    role = Accounts.get_role(conn.assigns.invitation.role_id)

    conn
    |> put_flash(:success, "Invitation deleted")
    |> redirect(to: "/admin/invitations?role=#{role.slug}")
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
    invitation = Accounts.get_invitation(conn.params["id"] || conn.params["invitation_id"], conn)

    if invitation do
      assign(conn, :invitation, invitation)
    else
      conn
      |> resp(404, "")
      |> halt()
    end
  end

  def invite_request_path(%{assigns: %{current_user: user}} = conn, path \\ "/admin/invitations") do
    case Flight.Accounts.is_superadmin?(user) do
      true -> "#{path}?school_id=#{Flight.SchoolScope.school_id(conn)}"
      false -> path
    end
  end
end
