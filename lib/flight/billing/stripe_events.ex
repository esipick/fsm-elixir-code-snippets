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
      IO.inspect(session, label: "Session")
      IO.inspect(event.account, label: "Account")

  end

  def process(%Stripe.Event{
    type: "checkout.session.async_payment_failed",
    data: %{object: %Stripe.Session{} = session}}) do
      IO.inspect(session, label: "Session")

  end

  def process(%Stripe.Event{
    type: "checkout.session.async_payment_succeeded",
    data: %{object: %Stripe.Session{} = session}}) do
      IO.inspect(session, label: "Session")

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
