defmodule FlightWeb.Billing.InvoiceStruct do
  alias __MODULE__
  alias Flight.{Repo, Accounts.User}
  alias FlightWeb.Billing.TransactionStruct

  defstruct ~w(
    appointment id school payer_name amount_due amount_paid status payment_date
    editable title total tax_rate total_tax line_items transactions demo
    amount_remainder created payment_method user_id bulk_transaction user is_admin_invoice notes payer_email
  )a

  def build(invoice) do
    invoice =
      invoice
      |> Repo.preload([
        :user,
        :school,
        :transactions,
        :bulk_transaction,
        :line_items,
        [appointment: [:user, :instructor_user, :mechanic_user, [aircraft: :inspections]]]
      ])
      %InvoiceStruct{
      id: invoice.id,
      user_id: invoice.user_id,
      created: invoice.inserted_at,
      school: invoice.school,
      payer_name: payer_name(invoice),
      amount_due: (if invoice.status == :paid or invoice.payment_option == :maintenance or invoice.total == 0, do: 0, else: invoice.total_amount_due),
      amount_paid: get_amount_paid(invoice),
      amount_remainder: amount_remainder(invoice),
      status: invoice.status,
      notes: invoice.notes,
      payer_email: payer_email(invoice),
      payment_date: invoice.date,
      payment_method: invoice.payment_option,
      editable: editable(invoice),
      title: title(invoice),
      total: invoice.total,
      tax_rate: invoice.tax_rate,
      total_tax: (if invoice.total == 0, do: 0, else: invoice.total_tax) ,
      line_items: invoice.line_items,
      transactions: transactions(invoice),
      user: invoice.user,
      bulk_transaction:
        Optional.map(
          invoice.bulk_transaction,
          &TransactionStruct.build(&1)
        ),
      appointment: invoice.appointment,
      is_admin_invoice: invoice.is_admin_invoice,
      demo: invoice.demo
    }
  end

  def build_skinny(invoice) do
    invoice =
      invoice
      |> Repo.preload([
        :transactions,
        :line_items
      ])


    %InvoiceStruct{
      id: invoice.id,
      user_id: invoice.user_id,
      created: invoice.inserted_at,
      amount_due: (if invoice.status == :paid, do: 0, else: invoice.total_amount_due),
      amount_paid: get_amount_paid(invoice),
      amount_remainder: amount_remainder(invoice),
      status: invoice.status,
      payment_date: invoice.date,
      payment_method: invoice.payment_option,
      editable: editable(invoice),
      title: title(invoice),
      total: invoice.total,
      tax_rate: invoice.tax_rate,
      total_tax: invoice.total_tax,
      line_items: invoice.line_items,
      transactions: transactions(invoice),
    }
  end

  defp payer_name(invoice) do
    if invoice.user do
      User.full_name(invoice.user)
    else
      invoice.payer_name
    end
  end

  defp payer_email(invoice) do
    cond do
      invoice.payer_email ->
        invoice.payer_email
      invoice.user ->
        invoice.user.email
      invoice.appointment && invoice.appointment.mechanic_user ->
        invoice.appointment.mechanic_user.email
      true ->
        ""
    end
  end

  defp get_amount_paid(invoice) do
    cond do
      invoice.payment_option == :maintenance ->
        0
      invoice.total == 0 ->
        0
      invoice.status == :paid ->
        invoice.total + invoice.total_tax
      true ->
        amount_paid(invoice)
    end
  end

  defp amount_paid(invoice) do
    completed_transactions(invoice)
    |> Enum.reduce(0, fn transaction, acc -> transaction.amount_paid + acc end)
  end

  defp editable(invoice) do
    invoice.status == :pending
  end

  defp title(invoice) do
    "Invoice ##{invoice.id} (#{invoice.status})"
  end

  defp transactions(invoice) do
    invoice.transactions
    |> Enum.map(fn transaction -> TransactionStruct.build(transaction) end)
  end

  defp amount_remainder(invoice) do
    invoice.total_amount_due - amount_paid(invoice)
  end

  defp completed_transactions(invoice) do
    transactions(invoice)
    |> Enum.filter(fn transaction -> transaction.state == "completed" end)
  end
end
