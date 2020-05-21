defmodule FlightWeb.StripeHelperTest do
  use ExUnit.Case

  test "change 'empty card' error message" do
    message =
      "You passed an empty string for 'card'.
      We assume empty values are an attempt to unset a parameter;
      however 'card' cannot be unset. You should remove 'card' from your request or supply a non-empty value."

    assert FlightWeb.StripeHelper.human_error(message) ==
             "Customer has no active credit or debit card attached."
  end

  test "change 'empty customer' error message" do
    message =
      "You passed an empty string for 'customer'.
      We assume empty values are an attempt to unset a parameter;
      however 'customer' cannot be unset. You should remove 'customer' from your request or supply a non-empty value."

    assert FlightWeb.StripeHelper.human_error(message) ==
             "Customer has no active credit or debit card attached."
  end

  test "does not change error message" do
    message = "Must authenticate as a connected account to be able to use customer parameter."

    assert FlightWeb.StripeHelper.human_error(message) ==
             "Must authenticate as a connected account to be able to use customer parameter."
  end
end
