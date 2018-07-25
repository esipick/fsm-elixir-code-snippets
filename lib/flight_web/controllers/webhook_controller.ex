defmodule FlightWeb.WebhookController do
  use FlightWeb, :controller

  def upcoming_appointment_notifications(conn, _) do
    Mondo.Task.start(fn ->
      Flight.BackgroundJob.send_upcoming_appointment_notifications()
    end)

    resp(conn, 200, "")
  end

  def outstanding_payments_notifications(conn, _) do
    Mondo.Task.start(fn ->
      Flight.BackgroundJob.send_outstanding_payments_notifications()
    end)

    resp(conn, 200, "")
  end
end
