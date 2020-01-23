defmodule FlightWeb.SessionController do
  use FlightWeb, :controller

  alias Flight.Accounts
  import Flight.Auth.Authorization
  alias Flight.Auth.Permission

  plug(:redirect_if_logged_in when action in [:login, :login_submit])

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def login_submit(conn, %{"email" => email, "password" => password}) do
    user = Accounts.get_user_by_email(email)

    if user do
      case Accounts.check_password(user, password) do
        {:ok, user} ->
          if user_can?(user, [Permission.new(:web_dashboard, :access, :all)]) do
            conn
            |> FlightWeb.AuthenticateWebUser.log_in(user.id)
            |> redirect(to: FlightWeb.RoleUtil.default_redirect_path(user))
          else
            conn
            |> put_flash(:error, "You are not allowed to log in.")
            |> redirect(to: "/login")
          end

        {:error, _} ->
          conn
          |> put_flash(:error, "Invalid username or password.")
          |> redirect(to: "/login")
      end
    else
      Comeonin.Bcrypt.dummy_checkpw()

      conn
      |> put_flash(:error, "Invalid username or password.")
      |> redirect(to: "/login")
    end
  end

  def logout(conn, _) do
    conn
    |> Plug.Conn.delete_resp_cookie("school_id")
    |> FlightWeb.AuthenticateWebUser.log_out()
    |> redirect(to: "/login")
  end

  defp redirect_if_logged_in(conn, _) do
    if get_session(conn, :user_id) do
      user = Accounts.dangerous_get_user(get_session(conn, :user_id))

      conn
      |> redirect(to: FlightWeb.RoleUtil.default_redirect_path(user))
      |> halt()
    else
      conn
    end
  end
end
