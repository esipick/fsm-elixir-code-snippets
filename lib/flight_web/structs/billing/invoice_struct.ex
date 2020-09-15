defmodule FlightWeb.Billing.InvoiceStruct do
  alias __MODULE__
  alias Flight.{Repo, Accounts.User}
  alias FlightWeb.Billing.TransactionStruct

  defstruct ~w(
    appointment id school payer_name amount_due amount_paid status payment_date
    editable title total tax_rate total_tax line_items transactions
    amount_remainder created payment_method user_id bulk_transaction user
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
        [appointment: [:user, :instructor_user, [aircraft: :inspections]]]
      ])

    %InvoiceStruct{
      id: invoice.id,
      user_id: invoice.user_id,
      created: invoice.inserted_at,
      school: invoice.school,
      payer_name: payer_name(invoice),
      amount_due: invoice.total_amount_due,
      amount_paid: amount_paid(invoice),
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
      user: invoice.user,
      bulk_transaction:
        Optional.map(
          invoice.bulk_transaction,
          &TransactionStruct.build(&1)
        ),
      appointment: invoice.appointment
    }
  end

  defp payer_name(invoice) do
    if invoice.user do
      User.full_name(invoice.user)
    else
      invoice.payer_name
    end
  end

  defp amount_paid(invoice) do
    completed_transactions(invoice)
    |> Enum.reduce(0, fn transaction, acc -> transaction.amount_due + acc end)
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
