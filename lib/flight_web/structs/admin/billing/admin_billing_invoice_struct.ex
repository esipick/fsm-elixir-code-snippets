defmodule FlightWeb.Admin.Billing.InvoiceStruct do
  alias __MODULE__
  alias Flight.{Repo, Accounts.User}

  defstruct ~w(id student_name amount_due amount_paid status payment_date payment_method)a

  def build(invoice) do
    invoice = invoice |> Repo.preload([:user, :transactions])

    %InvoiceStruct{
      id: invoice.id,
      student_name: student_name(invoice),
      amount_due: invoice.total_amount_due,
      amount_paid: amount_paid(invoice),
      status: invoice.status,
      payment_date: invoice.date,
      payment_method: payment_method(invoice)
    }
  end

  defp student_name(invoice) do
    User.full_name(invoice.user)
  end

  defp amount_paid(invoice) do
    invoice.transactions
    |> Enum.filter(fn transaction -> transaction.state == "completed" end)
    |> Enum.reduce(0, fn transaction, acc -> transaction.total + acc end)
  end

  defp payment_method(invoice) do
    if length(invoice.transactions) == 2 do
      "balance, cc"
    else
      invoice.payment_option
    end
  end
end
