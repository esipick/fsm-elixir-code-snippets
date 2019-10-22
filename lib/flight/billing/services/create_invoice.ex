defmodule Flight.Billing.CreateInvoice do
  import Ecto.Query

  alias Flight.Repo
  alias Flight.Accounts.User
  alias Flight.Billing.{Invoice, Transaction, PayTransaction}
  alias FlightWeb.Admin.Billing.InvoiceStruct

  def run(invoice_params, school_context) do
    pay_off = Map.get(school_context.params, "pay_off", false)

    result = case Invoice.create(invoice_params) do
      {:ok, invoice} ->
        if pay_off == true do
          case pay(invoice, school_context) do
            {:ok, invoice} -> {:ok, invoice}
            {:error, error} -> {:error, invoice.id, error}
          end
        else
          {:ok, invoice}
        end

      {:error, error} -> {:error, error}
    end

    result
  end

  def pay(invoice, school_context) do
    invoice = Repo.preload(invoice, user: (from i in User, lock: "FOR UPDATE NOWAIT"))

    case invoice.payment_option do
      :balance -> pay_off_balance(invoice, school_context)
      :cc -> pay_off_cc(invoice, school_context)
      _ -> pay_off_manually(invoice, school_context)
    end
  end

  defp pay_off_balance(invoice, school_context) do
    user_balance = invoice.user.balance
    total_amount_due = InvoiceStruct.build(invoice).amount_remainder

    if user_balance > 0 do
      remainder = user_balance - total_amount_due
      balance_enough = remainder >= 0
      total = if balance_enough, do: total_amount_due, else: user_balance

      case create_transaction(invoice, school_context, %{total: total, payment_option: :balance}) do
        {:ok, transaction} -> case PayTransaction.run(transaction) do
          {:ok, _} ->
            if balance_enough do
              Invoice.paid(invoice)
            else
              pay_off_cc(invoice, school_context, abs(remainder))
            end

          {:error, changeset} -> {:error, changeset}
        end

        {:error, changeset} -> {:error, changeset}
      end
    else
      pay_off_cc(invoice, school_context, total_amount_due)
    end
  end

  defp pay_off_cc(invoice, school_context, amount \\ nil) do
    amount = amount || invoice.total_amount_due
    transaction_attrs = %{type: "credit", total: amount, payment_option: :cc}

    case create_transaction(invoice, school_context, transaction_attrs) do
      {:ok, transaction} -> case PayTransaction.run(transaction) do
        {:ok, _} -> Invoice.paid(invoice)
        {:error, changeset} -> {:error, changeset}
      end

      {:error, changeset} -> {:error, changeset}
    end
  end

  defp pay_off_manually(invoice, school_context) do
    transaction_attrs = %{total: invoice.total_amount_due, payment_option: invoice.payment_option}

    case create_transaction(invoice, school_context, transaction_attrs) do
      {:ok, transaction} -> case PayTransaction.run(transaction) do
        {:ok, _} -> Invoice.paid(invoice)
        {:error, changeset} -> {:error, changeset}
      end

      {:error, changeset} -> {:error, changeset}
    end
  end

  defp create_transaction(invoice, school_context, attrs) do
    user = invoice.user

    %Transaction{
      state: "pending",
      type: "debit",
      user_id: user.id,
      invoice_id: invoice.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      creator_user_id: school_context.assigns.current_user.id,
      school_id: Flight.SchoolScope.school_id(school_context)
    }
    |> Transaction.changeset(attrs)
    |> Repo.insert
  end
end
