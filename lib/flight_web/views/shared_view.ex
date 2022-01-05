defmodule FlightWeb.SharedView do
  use FlightWeb, :view

  def page_sizes do
    [50, 75, 100, 200, 400, 600, 800, 1000]
  end

  def fetch_card(user) do
    if user.stripe_customer_id do
      case Stripe.Customer.retrieve(user.stripe_customer_id) do
        {:ok, customer} ->
          Enum.find(customer.sources.data, fn s -> s.id == customer.default_source end)

        _ ->
          nil
      end
    end
  end

  def card_date_class(card) do
    if expired?(card) do
      "text-expired"
    end
  end

  def expired?(card) do
    {:ok, expiry_date} = Date.new(card.exp_year, card.exp_month, 1)

    Date.compare(expiry_date, Timex.today()) == :lt
  end
end
