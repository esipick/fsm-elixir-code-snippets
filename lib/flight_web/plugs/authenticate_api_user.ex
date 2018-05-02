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
    with {:ok, id} <- user_id_from_token(token),
         %User{} = user <- Flight.Accounts.get_user(id) do
      {:ok, user}
    else
      _ ->
        {:error, "Invalid user authorization"}
    end
  end

  # Tokens

  def token(user, context \\ FlightWeb.Endpoint) do
    Phoenix.Token.sign(context, Application.get_env(:flight, :user_token_salt), user: user.id)
  end

  def user_id_from_token(token, context \\ FlightWeb.Endpoint) do
    case Phoenix.Token.verify(
           context,
           Application.get_env(:flight, :user_token_salt),
           token,
           max_age: 2_592_000
         ) do
      {:ok, [user: id]} ->
        {:ok, id}

      {:ok, _} ->
        {:error, :unknown_type}

      _ = error ->
        error
    end
  end
end
