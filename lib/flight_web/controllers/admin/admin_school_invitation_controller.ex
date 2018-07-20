defmodule FlightWeb.Admin.SchoolInvitationController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(FlightWeb.AuthorizeSuperadmin)
  plug(:get_invitation when action in [:resend])

  def index(conn, _) do
    invitations = Accounts.visible_school_invitations()

    render(
      conn,
      "index.html",
      invitations: invitations,
      changeset: Accounts.SchoolInvitation.create_changeset(%Accounts.SchoolInvitation{}, %{})
    )
  end

  def create(conn, %{"data" => data}) do
    case Accounts.create_school_invitation(data) do
      {:ok, invitation} ->
        conn
        |> put_flash(
          :success,
          "Successfully sent invitation."
        )
        |> redirect(to: "/admin/school_invitations")

      {:error, changeset} ->
        invitations = Accounts.visible_school_invitations()
        render(conn, "index.html", invitations: invitations, changeset: changeset)
    end
  end

  def resend(conn, _params) do
    Accounts.send_school_invitation_email(conn.assigns.invitation)

    conn
    |> put_flash(
      :success,
      "Successfully sent invitation email to #{conn.assigns.invitation.email}"
    )
    |> redirect(to: "/admin/school_invitations")
  end

  defp get_invitation(conn, _) do
    invitation =
      Accounts.get_school_invitation(conn.params["id"] || conn.params["school_invitation_id"])

    if invitation do
      assign(conn, :invitation, invitation)
    else
      conn
      |> resp(404, "")
      |> halt()
    end
  end
end
