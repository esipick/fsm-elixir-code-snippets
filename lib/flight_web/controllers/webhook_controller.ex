defmodule FlightWeb.WebhookController do
  use FlightWeb, :controller

  require Logger

  def upcoming_appointment_notifications(conn, _) do
    Mondo.Task.start(fn ->
      Logger.info("BackgroundJob:upcoming_appointment_notifications -- Sending...")
      appointments_count = Flight.BackgroundJob.send_upcoming_appointment_notifications()

      Logger.info(
        "BackgroundJob:upcoming_appointment_notifications -- Sent notifications for #{
          appointments_count
        } appointments."
      )
    end)

    resp(conn, 200, "")
  end

  def outstanding_payments_notifications(conn, _) do
    Mondo.Task.start(fn ->
      Logger.info("BackgroundJob:outstanding_payments_notifications -- Sending...")
      count = Flight.BackgroundJob.send_outstanding_payments_notifications()

      Logger.info(
        "BackgroundJob:outstanding_payments_notifications -- Sent notifications to #{count} users."
      )
    end)

    resp(conn, 200, "")
  end
end
