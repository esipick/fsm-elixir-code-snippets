defmodule FlightWeb.AuthenticateApiUser do
  import Plug.Conn

  alias Flight.Accounts.{User}
  require Ecto.Query

  def init(_opts) do
    :ok
  end

  def call(conn, _opts \\ []) do
    case user_from_authorization_header(conn) do
      {:ok, user} ->
        assign(conn, :current_user, user)

      _ ->
        conn
        |> send_resp(401, "")
        |> halt()
    end
  end

  def user_from_authorization_header(conn) do
    token =
      List.first(get_req_header(conn, "authorization")) ||
        fetch_query_params(conn).query_params["token"]

    authenticated_user(token)
  end

  def authenticated_user(token) do
    with {:ok, id, password_token} <- user_id_from_token(token),
         %User{} = user <- Flight.Repo.get(Flight.Accounts.User, id) do
      if user.archived do
        {:error, account_suspended_error}
      else
        case password_token == user.password_token do
          true -> {:ok, user}
          false -> {:error, "Password was changed. Sign out required"}
        end
      end
    else
      _ ->
        {:error, "Invalid user authentication"}
    end
  end

  # Tokens

  def token(user, context \\ FlightWeb.Endpoint) do
    Phoenix.Token.sign(context, Application.get_env(:flight, :user_token_salt), %{
      user: user.id,
      token: user.password_token
    })
  end

  def user_id_from_token(token, context \\ FlightWeb.Endpoint) do
    case Phoenix.Token.verify(
           context,
           Application.get_env(:flight, :user_token_salt),
           token,
           max_age: 1_000_592_000
         ) do
      {:ok, [user: id]} ->
        {:ok, id, nil}

      {:ok, %{user: id, token: password_token}} ->
        {:ok, id, password_token}

      {:ok, _} ->
        {:error, :unknown_type}

      _ = error ->
        error
    end
  end

  def account_suspended_error do
    "Account is suspended. Please contact your school administrator to reinstate it."
  end
end
