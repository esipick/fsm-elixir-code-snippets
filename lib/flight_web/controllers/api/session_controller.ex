defmodule FlightWeb.API.SessionController do
  use FlightWeb, :controller

  alias Flight.Accounts
  alias Flight.Accounts.User

  def api_login(conn, %{"email" => email, "password" => password}) do
    case user = Accounts.get_user_by_email(email) do
      %User{archived: true} ->
        conn
        |> put_status(401)
        |> json(%{human_errors: [FlightWeb.AuthenticateApiUser.account_suspended_error]})
      %User{archived: false} ->
        case Accounts.check_password(user, password) do
          {:ok, user} ->
            user =
              user
              |> FlightWeb.API.UserView.show_preload()

            render(conn, "login.json", user: user, token: FlightWeb.AuthenticateApiUser.token(user))

          {:error, _} ->
            conn
            |> put_status(401)
            |> json(%{human_errors: ["Invalid email or password."]})
        end
      _ ->
        Comeonin.Bcrypt.dummy_checkpw()

        conn
        |> put_status(401)
        |> json(%{human_errors: ["Invalid email or password."]})
    end
  end
end
