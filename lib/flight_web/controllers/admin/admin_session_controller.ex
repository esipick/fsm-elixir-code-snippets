defmodule FlightWeb.Admin.SessionController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(:redirect_if_logged_in when action in [:login, :login_submit])

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def login_submit(conn, %{"email" => email, "password" => password}) do
    user = Accounts.dangerous_get_user_by_email(email)

    if user do
      case Accounts.check_password(user, password) do
        {:ok, user} ->
          if Accounts.has_role?(user, "admin") do
            conn
            |> FlightWeb.AuthenticateWebUser.log_in(user.id)
            |> redirect(to: "/admin/dashboard")
          else
            conn
            |> put_flash(:error, "You must be an admin to log in.")
            |> redirect(to: "/admin/login")
          end

        {:error, _} ->
          conn
          |> put_flash(:error, "Invalid username or password.")
          |> redirect(to: "/admin/login")
      end
    else
      Comeonin.Bcrypt.dummy_checkpw()

      conn
      |> put_flash(:error, "Invalid username or password.")
      |> redirect(to: "/admin/login")
    end
  end

  def logout(conn, _) do
    conn
    |> FlightWeb.AuthenticateWebUser.log_out()
    |> redirect(to: "/admin/login")
  end

  defp redirect_if_logged_in(conn, _) do
    if get_session(conn, :user_id) do
      conn
      |> redirect(to: "/admin/dashboard")
      |> halt()
    else
      conn
    end
  end
end
