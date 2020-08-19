defmodule FlightWeb.StripeHelper do
  @no_card_msg "Customer has no active credit or debit card attached."

  def error_message(error) do
    error.user_message || error.message ||
      "There was a problem validating your card. Please try again or use another card."
  end

  def stripe_key() do
    Application.get_env(:flight, :stripe_publishable_key)
  end

  def human_error(%Stripe.Error{} = error) do
    param = Map.get(error.extra, :param)
    if param != nil, do: "#{inspect param}: " <> human_error(error.message), else: human_error(error.message)
  end

  def human_error(message) do
    cond do
      message =~ "passed an empty string for 'card'" ->
        @no_card_msg

      message =~ "passed an empty string for 'customer'" ->
        @no_card_msg

      true ->
        message
    end
  end
end
