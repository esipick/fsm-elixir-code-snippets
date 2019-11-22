defmodule FlightWeb.SchoolInvitationController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(:get_invitation)
  plug(:forward_to_settings_if_accepted)

  def accept(conn, _params) do
    render(
      conn,
      "accept.html",
      invitation: conn.assigns.invitation,
      changeset: Accounts.SchoolInvitation.user_create_changeset(conn.assigns.invitation)
    )
  end

  def accept_submit(conn, %{"user" => user_data}) do
    case Accounts.create_school_from_invitation(user_data, conn.assigns.invitation) do
      {:ok, {_school, user}} ->
        conn
        |> FlightWeb.AuthenticateWebUser.log_in(user.id)
        |> redirect(to: "/admin/settings")

      {:error, changeset} ->
        IO.inspect(changeset)
        render(conn, "accept.html", invitation: conn.assigns.invitation, changeset: changeset)
    end
  end

  defp get_invitation(conn, _) do
    invitation = Accounts.get_school_invitation_for_token(conn.params["token"])

    if invitation do
      assign(conn, :invitation, invitation)
    else
      # TODO: Not the right place...where to though?
      conn
      |> redirect(to: "/login")
      |> halt()
    end
  end

  defp forward_to_settings_if_accepted(conn, _) do
    if conn.assigns.invitation.accepted_at do
      conn
      |> redirect(to: "/admin/settings")
      |> halt
    else
      conn
    end
  end
end
