defmodule StripeHelper do
  def error_message(error) do
    error.user_message || error.message ||
      "There was a problem validating your card. Please try again or use another card."
  end

  def stripe_key() do
    Application.get_env(:flight, :stripe_publishable_key)
  end
end
