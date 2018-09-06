defmodule FlightWeb.InvitationController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(:get_invitation when action in [:accept, :accept_submit, :accept_success])
  plug(:forward_to_success_if_accepted when action in [:accept, :accept_submit])
  plug(:forward_to_accept_if_not_accepted when action in [:accept_success])

  def accept(conn, _params) do
    render(
      conn,
      "accept.html",
      invitation: conn.assigns.invitation,
      changeset: Accounts.Invitation.user_create_changeset(conn.assigns.invitation),
      stripe_error: nil
    )
  end

  def accept_submit(conn, %{"token" => token, "user" => user_data} = params) do
    case Accounts.create_user_from_invitation(
           user_data,
           params["stripe_token"],
           conn.assigns.invitation
         ) do
      {:ok, _user} ->
        redirect(conn, to: "/invitations/#{token}/success")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "accept.html",
          invitation: conn.assigns.invitation,
          changeset: changeset,
          stripe_error: nil
        )

      {:error, %Stripe.Error{} = error} ->
        render(
          conn,
          "accept.html",
          invitation: conn.assigns.invitation,
          changeset:
            Accounts.user_changeset(%Accounts.User{}, user_data, conn.assigns.invitation),
          stripe_error:
            error.user_message || error.message ||
              "There was a problem charging your card. Please try again."
        )
    end
  end

  def accept_success(conn, _) do
    render(conn, "success.html")
  end

  defp get_invitation(conn, _) do
    invitation = Accounts.get_invitation_for_token(conn.params["token"])

    if invitation do
      assign(conn, :invitation, invitation |> Flight.Repo.preload(:role))
    else
      # TODO: Not the right place...where to though?
      conn
      |> redirect(to: "/admin/login")
      |> halt()
    end
  end

  defp forward_to_success_if_accepted(conn, _) do
    if conn.assigns.invitation.accepted_at do
      conn
      |> redirect(to: "/invitations/#{conn.assigns.invitation.token}/success")
      |> halt
    else
      conn
    end
  end

  defp forward_to_accept_if_not_accepted(conn, _) do
    if !conn.assigns.invitation.accepted_at do
      conn
      |> redirect(to: "/invitations/#{conn.assigns.invitation.token}")
      |> halt
    else
      conn
    end
  end
end
