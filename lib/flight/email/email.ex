defmodule Flight.Email do
  import Bamboo.Email
  use Bamboo.Phoenix, view: FlightWeb.EmailView

  def invitation_email(invitation) do
    new_email()
    |> to(invitation.email)
    # TODO: What email address to use here?
    |> from("noreply@randonaviation.com")
    |> subject("Welcome to Randon Aviation!")
    |> render("invitation.html", link: invitation_link(invitation))
  end

  defp invitation_link(invitation) do
    Application.get_env(:flight, :web_base_url) <> "/invitations/#{invitation.token}"
  end
end
