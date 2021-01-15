defmodule FlightWeb.Context do
  @behaviour Plug
  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    IO.inspect(context, label: "context")
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp get_remote_ip(nil), do: nil
  defp get_remote_ip(ip) do
    ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp build_context(conn) do
    Logger.debug("request_headers: #{inspect(conn.req_headers)}")
    remote_ip = get_remote_ip(conn.remote_ip)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
    {:ok, id, password_token} <- user_id_from_token(token),
    user <- Fsm.Accounts.get_user_with_roles(id) do
      current_user = %{id: user.id, school_id: Map.get(user, :school_id), roles: user.roles}
#      Logger.info fn -> "roles: #{inspect user.roles}" end
      %{current_user: current_user}
    else
      _ ->
        Logger.metadata([remote_ip: remote_ip])
        %{}
    end
  end

  def user_id_from_token(token, context \\ FlightWeb.Endpoint) do
    case Phoenix.Token.verify(
           context,
           Application.get_env(:flight, :user_token_salt),
           token,
           max_age: 1_000_592_000
         ) do
      {:ok, [user_id: id]} ->
        {:ok, id, nil}

      {:ok, %{user_id: id, token: password_token}} ->
        {:ok, id, password_token}

      {:ok, _} ->
        {:error, :unknown_type}

      _ = error ->
        error
    end
  end
end
