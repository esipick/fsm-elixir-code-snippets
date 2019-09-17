defmodule FlightWeb.Admin.CommunicationController do
  use FlightWeb, :controller

  alias Flight.Email
  alias Flight.Mailer
  alias Flight.Accounts

  def index(conn, _) do
    redirect(conn, to: communication_path(conn, :new))
  end

  def new(conn, _) do
    conn
    |> render(
      "new.html",
      changeset: Email.message_changeset(%{})
    )
  end

  def create(conn, %{"data" => params}) do
    recipients =
      conn
      |> Flight.SchoolScope.get_school()
      |> Accounts.get_users()

    case Email.admin_create_communication_email(recipients, params) do
      {:ok, email} ->
        email
        |> Mailer.deliver_now()

        conn
        |> put_flash(:success, "Successfully sent email.")
        |> redirect(to: communication_path(conn, :new))

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end
end
