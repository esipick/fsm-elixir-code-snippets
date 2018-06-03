defmodule FlightWeb.API.SessionController do
  use FlightWeb, :controller

  alias Flight.Accounts

  def api_login(conn, %{"email" => email, "password" => password}) do
    user = Accounts.get_user_by_email(email)

    if user do
      case Accounts.check_password(user, password) do
        {:ok, user} ->
          render(conn, "login.json", user: user, token: FlightWeb.AuthenticateApiUser.token(user))

        {:error, _} ->
          conn
          |> put_status(401)
          |> json(%{errors: ["Invalid email or password."]})
      end
    else
      Comeonin.Bcrypt.dummy_checkpw()

      conn
      |> put_status(401)
      |> json(%{errors: ["Invalid email or password."]})
    end
  end
end
