defmodule FlightWeb.Billing.TransactionStruct do
  alias __MODULE__
  alias Flight.Billing.Transaction
  alias Flight.Accounts.User
  alias Flight.Repo

  defstruct ~w(
    id invoice_id school student_name amount_due amount_paid state completed_at
    payment_method error_message created title bulk_invoices guest payer_email
  )a

  def build(transaction, opts \\ %{}) do
    transaction = Repo.preload(transaction, [:user])

    struct(TransactionStruct, base_params(transaction, opts))
  end

  defp base_params(transaction, opts) do
    %{
      id: transaction.id,
      created: transaction.inserted_at,
      school: transaction.school,
      invoice_id: transaction.invoice_id,
      student_name: student_name(transaction),
      payer_email: transaction.email,
      amount_due: (if transaction.state == "completed", do: 0, else: transaction.total),
      amount_paid: (if transaction.state == "completed", do: transaction.total, else: 0),
      state: transaction.state,
      completed_at: transaction.completed_at,
      payment_method: transaction.payment_option,
      error_message: transaction.error_message,
      bulk_invoices: if(opts[:render_invoices], do: bulk_invoices(transaction), else: []),
      title: title(transaction),
      guest: is_nil(transaction.user)
    }
  end

  defp bulk_invoices(transaction) do
    transaction = Repo.preload(transaction, :bulk_invoices)

    Enum.map(transaction.bulk_invoices, fn i ->
      %{
        id: i.id,
        date: i.date,
        total_amount_due: i.total_amount_due,
        status: i.status
      }
    end)
  end

  defp student_name(transaction) do
    if transaction.user do
      User.full_name(transaction.user)
    else
      Transaction.full_name(transaction)
    end
  end

  defp amount_paid(transaction) do
    Map.get(transaction, Transaction.get_paid_by_column(transaction)) || 0
  end

  defp title(transaction) do
    "Transaction ##{transaction.id} (#{transaction.state})"
  end
end
