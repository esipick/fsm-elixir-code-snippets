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

  def invitation_link(%Invitation{} = invitation) do
    Application.get_env(:flight, :web_base_url) <> "/invitations/#{invitation.token}"
  end

  def school_invitation_link(%SchoolInvitation{} = invitation) do
    Application.get_env(:flight, :web_base_url) <> "/school_invitations/#{invitation.token}"
  end
end
