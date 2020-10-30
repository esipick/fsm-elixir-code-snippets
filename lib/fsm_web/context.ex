defmodule FlightWeb.Context do
  @behaviour Plug
  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(conn, _) do
    IO.inspect(conn, label: "fsdfsd")
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
         {:ok, claims} <- Phoenix.Token.verify(FlightWeb.Endpoint, Application.get_env(:flight, :user_token_salt), token, max_age: 86400)
#         {:ok, claims_1} <- Phoenix.Token.decrypt(conn, Application.get_env(:flight, :user_token_salt), token),
      do
    Logger.info fn -> "context user: #{inspect claims}" end
      Logger.metadata([user_id: claims.user_id, role: claims.role, remote_ip: remote_ip])
      %{current_user: claims}
    else
      _ ->
        Logger.metadata([remote_ip: remote_ip])
        %{}
    end
  end
end
