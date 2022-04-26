defmodule Flight.Email do
  import Bamboo.Email
  import Bamboo.SendGridHelper
  use Bamboo.Phoenix, view: FlightWeb.EmailView

  alias Flight.Accounts.{Invitation, SchoolInvitation, User}
  alias Flight.Repo

  def unavailability_email(%User{} = user) do
    new_email()
    |> to(user.email)
    |> from({"Flight School Manager", "noreply@flightschoolmanager.co"})
    |> with_template(Application.get_env(:flight, :appointment_unavailability_template_id))
    |> add_dynamic_field("FIRST_NAME", user.first_name)
    |> IO.inspect()
  end

  def unavailability_email(user) when user == nil do
    IO.puts "User is undefined"
  end

  def invitation_email(%Invitation{} = invitation) do
    role = Flight.Accounts.get_role(invitation.role_id)
    invitation = Repo.preload(invitation, :school)
    company_name = invitation.school.name

    new_email()
    |> to(invitation.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    # TODO: What email address to use here?
    |> from({company_name, "noreply@flightschoolmanager.co"})
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
    |> from({"Flight School Manager", "noreply@flightschoolmanager.co"})
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
    |> from({"Flight School Manager", "noreply@flightschoolmanager.co"})
    |> subject("Password Reset - Flight School Manager")
    |> render(
      "_reset_password.html",
      password_reset: password_reset,
      password_reset_link: password_reset_link(password_reset)
    )
  end

  # def invoice_email(to, _invoice_no, html) when is_nil(to) or is_nil(html), do: :error
  # def invoice_email(to, invoice_no, html) do

    # new_email()
    # |> to(to)
    # |> from("noreply@flightschoolmanager.co")
    # |> subject("Invoice# #{invoice_no} - Flight School Manager")
    # |> html_body(html)
  # end

  def invoice_email(to, _invoice_no, path) when is_nil(to) or is_nil(path), do: :error
  def invoice_email(to, invoice_no, path) do
    attachment = Bamboo.Attachment.new(path, filename: "invoice-#{invoice_no}.pdf", content_type: "application/pdf")
    IO.inspect("attachment: #{inspect attachment}")
    new_email()
    |> to(to)
    |> from({"Flight School Manager", "noreply@flightschoolmanager.co"})
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

  def squawk_created_email_notification(destination_user, creating_user, squawk) do
    # attachment = Bamboo.Attachment.new(path, filename: "invoice-#{invoice_no}.pdf", content_type: "application/pdf")
    # IO.inspect("attachment: #{inspect attachment}")
    new_email()
    |> to(destination_user.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    |> from({"Flight School Manager", "noreply@flightschoolmanager.co"})
    |> subject("Squawk Created")
    |> render(
      "_squawk.html",
      operation: "created",
      by_user_name: creating_user.first_name <> " " <> creating_user.last_name,
      destination_user_first_name: destination_user.first_name,
      squawk_aircraft_make: squawk.aircraft.make,
      squawk_aircraft_model: squawk.aircraft.model,
      squawk_aircraft_tail_number: squawk.aircraft.tail_number
    )
    # |> put_attachment(attachment)
  end

  def squawk_updated_email_notification(destination_user, updating_user, squawk) do
    # attachment = Bamboo.Attachment.new(path, filename: "invoice-#{invoice_no}.pdf", content_type: "application/pdf")
    # IO.inspect("attachment: #{inspect attachment}")
    new_email()
    |> to(destination_user.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    |> from({"Flight School Manager", "noreply@flightschoolmanager.co"})
    |> subject("Squawk Updated")
    |> render(
      "_squawk.html",
      operation: "updated",
      by_user_name: updating_user.first_name <> " " <> updating_user.last_name,
      destination_user_first_name: destination_user.first_name,
      squawk_aircraft_make: squawk.aircraft.make,
      squawk_aircraft_model: squawk.aircraft.model,
      squawk_aircraft_tail_number: squawk.aircraft.tail_number
    )
    # |> put_attachment(attachment)
  end

  def squawk_deleted_email_notification(destination_user, deleting_user, squawk) do
    # attachment = Bamboo.Attachment.new(path, filename: "invoice-#{invoice_no}.pdf", content_type: "application/pdf")
    # IO.inspect("attachment: #{inspect attachment}")
    new_email()
    |> to(destination_user.email)
    |> put_layout({FlightWeb.EmailView, "invitation"})
    |> from({"Flight School Manager", "noreply@flightschoolmanager.co"})
    |> subject("Squawk Deleted")
    |> render(
      "_squawk.html",
      operation: "deleted",
      by_user_name: deleting_user.first_name <> " " <> deleting_user.last_name,
      destination_user_first_name: destination_user.first_name,
      squawk_aircraft_make: squawk.aircraft.make,
      squawk_aircraft_model: squawk.aircraft.model,
      squawk_aircraft_tail_number: squawk.aircraft.tail_number
    )
    # |> put_attachment(attachment)
  end
end
