defmodule FlightWeb.WebhookControllerTest do
  use FlightWeb.ConnCase

  describe "POST upcoming_appointment_notifications" do
    test "doesn't throw errors", %{conn: conn} do
      conn
      |> post(
        "/webhooks/upcoming_appointment_notifications?token=#{
          Application.get_env(:flight, :webhook_token)
        }"
      )
      |> response(200)
    end
  end

  describe "POST outstanding_payments_notifications" do
    test "doesn't throw errors", %{conn: conn} do
      conn
      |> post(
        "/webhooks/outstanding_payments_notifications?token=#{
          Application.get_env(:flight, :webhook_token)
        }"
      )
      |> response(200)
    end
  end
end
