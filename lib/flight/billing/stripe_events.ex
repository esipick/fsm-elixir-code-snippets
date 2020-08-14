defmodule Flight.Billing.StripeEvents do
  alias Flight.Accounts.{StripeAccount}

  def process(%Stripe.Event{
        type: "account.updated",
        data: %{object: %Stripe.Account{} = api_account}
      }) do
    with %StripeAccount{} = account <-
           Flight.Billing.get_stripe_account_by_account_id(api_account.id) do
      Flight.Billing.update_stripe_account(account, api_account)
    else
      _error ->
        :nothing
    end
  end

  def process(%Stripe.Event{
    type: "checkout.session.completed",
    data: %{object: %Stripe.Session{} = session} = event}) do
      Flight.Billing.Invoice.get_by_session_id(session.id)
      |> Flight.Billing.Invoice.paid_by_cc
  end

  def process(%Stripe.Event{
    type: "payment_intent.succeeded",
    data: %{object: %Stripe.PaymentIntent{} = session} = event}) do
      Flight.Billing.Invoice.get_by_session_id(session.id)
      |> Flight.Billing.Invoice.paid_by_cc
  end
  

  def process(%Stripe.Event{type: "account.application.deauthorized", account: account_id}) do
    stripe_account = Flight.Billing.get_stripe_account_by_account_id(account_id)

    if stripe_account do
      Flight.Repo.delete!(stripe_account)
    end
  end

  def process(%Stripe.Event{}) do
    :ok
  end
end
