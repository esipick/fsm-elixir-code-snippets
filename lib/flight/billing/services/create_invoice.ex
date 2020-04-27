defmodule Flight.Billing.CreateInvoice do
  import Ecto.Query

  alias Flight.Repo
  alias Flight.Accounts.User
  alias Flight.Billing.{Invoice, Transaction, PayTransaction}
  alias FlightWeb.Billing.InvoiceStruct
  alias Flight.Scheduling.{Appointment, Aircraft}

  def run(invoice_params, school_context) do
    pay_off = Map.get(school_context.params, "pay_off", false)
    school = school(school_context)

    invoice_attrs =
      Map.merge(
        invoice_params,
        %{"school_id" => school.id, "tax_rate" => school.sales_tax || 0}
      )

    case Invoice.create(invoice_attrs) do
      {:ok, invoice} ->
        if pay_off == true do
          case pay(invoice, school_context) do
            {:ok, invoice} -> {:ok, invoice}
            {:error, error} -> {:error, invoice.id, error}
          end
        else
          {:ok, invoice}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def pay(invoice, school_context) do
    invoice =
      Repo.preload(invoice, user: from(i in User, lock: "FOR UPDATE NOWAIT"))
      |> Repo.preload(:appointment)

    case process_payment(invoice, school_context) do
      {:ok, invoice} ->
        if invoice.appointment do
          Appointment.paid(invoice.appointment)
        end

        line_item = Enum.find(invoice.line_items, fn i -> i.hobbs_tach_used end)

        if line_item do
          aircraft = Repo.get(Aircraft, line_item.aircraft_id)

          {:ok, _} =
            aircraft
            |> Aircraft.changeset(%{
              last_tach_time: line_item.tach_end,
              last_hobbs_time: line_item.hobbs_end
            })
            |> Flight.Repo.update()
        end

        {:ok, invoice}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp process_payment(invoice, school_context) do
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
        {:ok, transaction} ->
          case PayTransaction.run(transaction) do
            {:ok, _} ->
              if balance_enough do
                Invoice.paid(invoice)
              else
                pay_off_cc(invoice, school_context, abs(remainder))
              end

            {:error, changeset} ->
              {:error, changeset}
          end

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      pay_off_cc(invoice, school_context, total_amount_due)
    end
  end

  defp pay_off_cc(invoice, school_context, amount \\ nil) do
    amount = amount || invoice.total_amount_due
    transaction_attrs = %{type: "credit", total: amount, payment_option: :cc}

    case create_transaction(invoice, school_context, transaction_attrs) do
      {:ok, transaction} ->
        case PayTransaction.run(transaction) do
          {:ok, _} -> Invoice.paid_by_cc(invoice)
          {:error, changeset} -> {:error, changeset}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp pay_off_manually(invoice, school_context) do
    transaction_attrs = %{total: invoice.total_amount_due, payment_option: invoice.payment_option}

    case create_transaction(invoice, school_context, transaction_attrs) do
      {:ok, transaction} ->
        case PayTransaction.run(transaction) do
          {:ok, _} -> Invoice.paid(invoice)
          {:error, changeset} -> {:error, changeset}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp create_transaction(invoice, school_context, attrs) do
    user = invoice.user
    first_name = if user, do: user.first_name, else: invoice.payer_name

    %Transaction{
      state: "pending",
      type: "debit",
      user_id: user && user.id,
      invoice_id: invoice.id,
      email: user && user.email,
      first_name: first_name,
      last_name: user && user.last_name,
      creator_user_id: school_context.assigns.current_user.id,
      school_id: school(school_context).id
    }
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end
end
