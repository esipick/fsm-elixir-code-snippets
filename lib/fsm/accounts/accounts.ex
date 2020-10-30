defmodule Fsm.Accounts do
  import Ecto.Query, warn: false

  alias Flight.Repo

  alias Fsm.Accounts.User

  require Logger

  def api_login(%{"email" => email, "password" => password}) do

    case user = get_user_by_email(email) do
      %User{archived: true} ->
        {:error, %{human_errors: [FlightWeb.AuthenticateApiUser.account_suspended_error()]}}

      %User{archived: false} ->
        case check_password(user, password) do
          {:ok, user} ->
            user =
              user
              |> FlightWeb.API.UserView.show_preload()

            {:ok, %{user: user, token: FlightWeb.Fsm.AuthenticateApiUser.token(user)}}

          {:error, _} ->
            {:error, "Invalid email or password."}
        end

      _ ->
        Comeonin.Bcrypt.dummy_checkpw()

        {:error, "Invalid email or password."}
    end
  end

  def get_user(id) do
    user = 
    Fsm.Accounts.UserQueries.get_user_with_roles(id)
    |> Repo.one
  end
  defp get_user_by_email(email) when is_nil(email) or email == "", do: nil

  defp get_user_by_email(email) do
    User
    |> where([u], u.email == ^String.downcase(email))
    |> Repo.one()
  end

  defp check_password(user, password) do
    Comeonin.Bcrypt.check_pass(user, password)
  end
end
