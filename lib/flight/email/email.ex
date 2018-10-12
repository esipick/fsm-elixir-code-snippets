defmodule Flight.Email do
  import Bamboo.Email
  use Bamboo.Phoenix, view: FlightWeb.EmailView

  alias Flight.Accounts.{Invitation, SchoolInvitation}

  def invitation_email(%Invitation{} = invitation) do
    role = Flight.Accounts.get_role(invitation.role_id)

    new_email()
    |> to(invitation.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    # TODO: What email address to use here?
    |> from("noreply@randonaviation.com")
    |> subject("Welcome to Randon Aviation!")
    |> render(
      "_user_invitation.html",
      link: invitation_link(invitation),
      company_name: "Randon Aviation",
      first_name: invitation.first_name,
      role: role.slug
    )
  end

  def school_invitation_email(%SchoolInvitation{} = invitation) do
    new_email()
    |> to(invitation.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    # TODO: What email address to use here?
    |> from("noreply@randonaviation.com")
    |> subject("Welcome to Flight School Manager!")
    |> render(
      "_school_invitation.html",
      link: school_invitation_link(invitation)
    )
  end

  def reset_password_email(%Flight.Accounts.PasswordReset{} = password_reset) do
    new_email()
    |> to(password_reset.user.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    # TODO: What email address to use here?
    |> from("noreply@randonaviation.com")
    |> subject("Password Reset - Flight School Manager")
    |> render(
      "_reset_password.html",
      password_reset: password_reset,
      password_reset_link: password_reset_link(password_reset)
    )
  end

  def invitation_link(%Invitation{} = invitation) do
    Application.get_env(:flight, :web_base_url) <> "/invitations/#{invitation.token}"
  end

  def school_invitation_link(%SchoolInvitation{} = invitation) do
    Application.get_env(:flight, :web_base_url) <> "/school_invitations/#{invitation.token}"
  end

  def password_reset_link(%Flight.Accounts.PasswordReset{} = reset) do
    Application.get_env(:flight, :web_base_url) <> "/password_reset/#{reset.token}"
  end
end
