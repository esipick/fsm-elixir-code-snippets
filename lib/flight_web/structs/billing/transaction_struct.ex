defmodule FlightWeb.Billing.TransactionStruct do
  alias __MODULE__
  alias Flight.Billing.Transaction
  alias Flight.Accounts.User
  alias Flight.Repo

  defstruct ~w(
    id invoice_id student_name amount_due amount_paid state completed_at
    payment_method error_message created
  )a

  def build(transaction) do
    transaction = Repo.preload(transaction, [:user])

    %TransactionStruct{
      id: transaction.id,
      created: NaiveDateTime.to_date(transaction.inserted_at),
      invoice_id: transaction.invoice_id,
      student_name: student_name(transaction),
      amount_due: transaction.total,
      amount_paid: amount_paid(transaction),
      state: transaction.state,
      completed_at: completed_at(transaction),
      payment_method: transaction.payment_option,
      error_message: transaction.error_message
    }
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

  defp completed_at(transaction) do
    transaction.completed_at && NaiveDateTime.to_date(transaction.completed_at)
  end
end
