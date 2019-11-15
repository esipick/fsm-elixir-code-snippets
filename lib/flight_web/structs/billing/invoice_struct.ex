defmodule FlightWeb.Billing.InvoiceStruct do
  alias __MODULE__
  alias Flight.{Repo, Accounts.User}
  alias FlightWeb.Billing.TransactionStruct

  defstruct ~w(
    id student_name amount_due amount_paid status payment_date payment_method
    editable title total tax_rate total_tax line_items transactions
    amount_remainder created
  )a

  def build(invoice) do
    invoice = invoice |> Repo.preload([:user, :transactions, :line_items])

    %InvoiceStruct{
      id: invoice.id,
      created: NaiveDateTime.to_date(invoice.inserted_at),
      student_name: student_name(invoice),
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
      transactions: transactions(invoice)
    }
  end

  defp student_name(invoice) do
    User.full_name(invoice.user)
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
