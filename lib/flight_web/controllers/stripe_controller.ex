defmodule FlightWeb.API.StripeController do
  use FlightWeb, :controller

  def stripe_events(conn, params) do
    payload = conn.assigns.raw_body
    header = List.first(get_req_header(conn, "stripe-signature"))
    secret = Application.get_env(:flight, :stripe_webhook_secret)

    case Stripe.Webhook.construct_event(payload, header, secret) do
      {:ok, event} ->
        if event.livemode == Application.get_env(:flight, :stripe_livemode, false) do
          Flight.Billing.StripeEvents.process(event)
        end

      _error ->       
        :nothing
    end

    resp(conn, 200, "")
  end

  # def checkout_completed(conn, params) do
  #   IO.inspect(conn, label: "Connection")
  #   IO.inspect(params, label: "Params")

  #   payload = conn.assigns.raw_body
  #   header = List.first(get_req_header(conn, "stripe-signature"))
  #   secret = Application.get_env(:flight, :stripe_webhook_secret)
    
  #   case Stripe.Webhook.construct_event(payload, header, secret) do
  #     {:ok, event} ->
  #       # if event.livemode == Application.get_env(:flight, :stripe_livemode, false) do
  #         Flight.Billing.StripeEvents.process(event)
  #       # end

  #     _ ->
  #       :nothing
  #   end

  #   resp(conn, 200, "")
  # end


end
