defmodule FlightWeb.AuthenticateWebhookTest do
  use FlightWeb.ConnCase

  test "passes with token", %{conn: conn} do
    conn = %{conn | query_params: %{"token" => Application.get_env(:flight, :webhook_token)}}

    conn =
      conn
      |> FlightWeb.AuthenticateWebhook.call([])

    refute conn.halted
  end

  test "halts without token", %{conn: conn} do
    conn =
      conn
      |> FlightWeb.AuthenticateWebhook.call([])

    assert conn.halted
  end
end
