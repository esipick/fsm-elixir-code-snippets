defmodule FlightWeb.API.StripeController do
  use FlightWeb, :controller

  def stripe_events(conn, _params) do
    payload = conn.assigns.raw_body
    header = List.first(get_req_header(conn, "stripe-signature"))
    secret = Application.get_env(:flight, :stripe_webhook_secret)

    case Stripe.Webhook.construct_event(payload, header, secret) do
      {:ok, event} -> Flight.Billing.StripeEvents.process(event)
      _ -> :nothing
    end

    resp(conn, 200, "")
  end
end
