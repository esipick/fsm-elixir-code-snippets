defmodule Flight.Billing.StripeEvents do
  alias Flight.Accounts.{StripeAccount}
  alias Flight.Scheduling.Appointment
  alias Flight.Billing.{
    CreateInvoice,
    PayTransaction
  }

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
    data: %{object: %Stripe.Session{} = session}}) do
      update_invoice_status(session.id)
  end

  def process(%Stripe.Event{
    type: "payment_intent.succeeded",
    data: %{object: %Stripe.PaymentIntent{} = session}}) do
      update_invoice_status(session.id)
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

  defp update_invoice_status(session_id) do
    with %{appointment_id: apmnt_id} = invoice <- Flight.Billing.Invoice.get_by_session_id(session_id),
        {:ok, invoice} <- Flight.Billing.Invoice.paid_by_cc(invoice) do

          if apmnt_id != nil do
            Flight.Repo.get(Appointment, apmnt_id)
            |> case do
              %{id: _id} = appointment -> Appointment.paid(appointment)
                _ -> nil
            end
          end

          with {:ok, transaction} <- PayTransaction.pay_demo_invoice_cc_transaction(invoice.id, invoice.user_id) do
            invoice = Flight.Repo.preload(invoice, [:line_items])

            school_context = %{school_id: invoice.school_id}

            # Here paid check is unnecessary however to just show that
            # only paid invoice can be sent
            if(invoice.status == :paid) do
              Flight.InvoiceEmail.send_paid_invoice_email(invoice, school_context)
            end

            CreateInvoice.insert_transaction_line_items(invoice, school_context, transaction)
          end
    else
      _ -> {:error, "Couldn't update appointment status"}
    end
  end
end
