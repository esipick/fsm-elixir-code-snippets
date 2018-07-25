defmodule FlightWeb.AuthenticateWebhook do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts \\ []) do
    conn = fetch_query_params(conn)
    token = Application.get_env(:flight, :webhook_token)

    if !token do
      raise "webhook_token not set!"
    end

    if token == (conn.query_params["token"] || "") do
      conn
    else
      conn
      |> resp(401, "")
      |> halt()
    end
  end
end
