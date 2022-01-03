defmodule Flight.Email do
  import Bamboo.Email
  use Bamboo.Phoenix, view: FlightWeb.EmailView

  alias Flight.Accounts.{Invitation, SchoolInvitation}
  alias Flight.Repo

  # System Emails

  def invitation_email(%Invitation{} = invitation) do
    role = Flight.Accounts.get_role(invitation.role_id)
    invitation = Repo.preload(invitation, :school)
    company_name = invitation.school.name

    new_email()
    |> to(invitation.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    # TODO: What email address to use here?
    |> from("noreply@flightschoolmanager.co")
    |> subject("Welcome to "<>company_name<>"!")
    |> render(
      "_user_invitation.html",
      link: invitation_link(invitation),
      company_name: company_name,
      first_name: invitation.first_name,
      role: role.slug
    )
  end

  def school_invitation_email(%SchoolInvitation{} = invitation) do
    new_email()
    |> to(invitation.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    # TODO: What email address to use here?
    |> from("noreply@flightschoolmanager.co")
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
    |> from("noreply@flightschoolmanager.co")
    |> subject("Password Reset - Flight School Manager")
    |> render(
      "_reset_password.html",
      password_reset: password_reset,
      password_reset_link: password_reset_link(password_reset)
    )
  end

  # def invoice_email(to, _invoice_no, html) when is_nil(to) or is_nil(html), do: :error
  # def invoice_email(to, invoice_no, html) do
    
  #   new_email()
  #   |> to(to)
  #   |> from("noreply@flightschoolmanager.co")
  #   |> subject("Invoice# #{invoice_no} - Flight School Manager")
  #   |> html_body(html)
  # end 

  def invoice_email(to, _invoice_no, path) when is_nil(to) or is_nil(path), do: :error
  def invoice_email(to, invoice_no, path) do
    attachment = Bamboo.Attachment.new(path, filename: "invoice-#{invoice_no}.pdf", content_type: "application/pdf")
    
    new_email()
    |> to(to)
    |> from("noreply@flightschoolmanager.co")
    |> subject("Invoice# #{invoice_no} - Flight School Manager")
    |> html_body("Invoice# #{invoice_no} - Flight School Manager")
    |> put_attachment(attachment)
    # |> html_body(invoice_html)
  end 

  def invitation_link(%Invitation{} = invitation) do
    Application.get_env(:flight, :web_base_url) <> "/invitations/token?token=#{invitation.token}"
  end

  def school_invitation_link(%SchoolInvitation{} = invitation) do
    Application.get_env(:flight, :web_base_url) <> "/school_invitations?token=#{invitation.token}"
  end

  def password_reset_link(%Flight.Accounts.PasswordReset{} = reset) do
    Application.get_env(:flight, :web_base_url) <> "/reset_password?token=#{reset.token}"
  end

  # Communication Emails

  @mail_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
  # ensure that the email looks valid
  def validate_email(changeset, field) do
    changeset
    |> Ecto.Changeset.validate_format(field, @mail_regex, message: "Invalid email format")
  end

  def message_changeset(params) do
    types = %{
      from: :string,
      subject: :string,
      body: :string
    }

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:subject, :body])
    |> Ecto.Changeset.validate_required(:from, message: "Email can't be blank")
    |> validate_email(:from)
  end

  def admin_create_communication_email([to | bcc], params) do
    changeset = message_changeset(params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, data} ->
        email =
          new_email()
          |> to(to)
          |> bcc(bcc)
          |> from(data.from)
          |> subject(data.subject)
          |> text_body(data.body)
          |> html_body("<p>#{data.body}</p>")

        {:ok, email}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
