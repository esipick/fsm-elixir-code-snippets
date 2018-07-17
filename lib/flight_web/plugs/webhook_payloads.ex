defmodule Flight.WebhookPayloads do
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)

    conn =
      if conn.request_path == "/api/stripe_events" do
        update_in(conn.assigns[:raw_body], &[body | &1 || []])
      else
        conn
      end

    {:ok, body, conn}
  end
end
