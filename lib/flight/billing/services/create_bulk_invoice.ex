defmodule Flight.Billing.CreateBulkInvoice do
  import Ecto.Query, warn: false

  alias Flight.Accounts.User
  alias Flight.Billing.{Invoice, BulkInvoice, PayOff}
  alias Flight.Repo

  def run(invoice_params, school_context) do
    school = school(school_context)
    invoice_attrs = Map.merge(invoice_params, %{"school_id" => school.id})
    invoice_ids = invoice_params["invoice_ids"]

    case BulkInvoice.create(invoice_attrs) do
      {:ok, bulk_invoice} ->
        update_invoices(invoice_ids, bulk_invoice_id: bulk_invoice.id)

        bulk_invoice = Repo.preload(bulk_invoice, :user)

        case pay(bulk_invoice, school_context, invoice_ids) do
          {:ok, bulk_invoice} -> {:ok, bulk_invoice}
          {:error, error} -> {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def pay(bulk_invoice, school_context, invoice_ids) do
    case process_payment(bulk_invoice, school_context) do
      {:ok, bulk_invoice} ->
        {_, invoices} = update_invoices(invoice_ids, status: 1)
        Flight.Billing.CreateInvoice.insert_bulk_invoice_line_items(bulk_invoice, invoices, school_context)

        {:ok, bulk_invoice}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp process_payment(bulk_invoice, school_context) do
    case bulk_invoice.payment_option do
      :balance -> pay_off_balance(bulk_invoice, school_context)
      :cc -> pay_off_cc(bulk_invoice, school_context)
      _ -> pay_off_manually(bulk_invoice, school_context)
    end
  end

  defp pay_off_balance(bulk_invoice, school_context) do
    total_amount_due = bulk_invoice.total_amount_due

    transaction_attrs =
      transaction_attributes(bulk_invoice)
      |> Map.merge(%{total: total_amount_due})

    case PayOff.balance(bulk_invoice.user, transaction_attrs, school_context) do
      {:ok, :balance_enough, _} ->
        BulkInvoice.paid(bulk_invoice)

      {:ok, :balance_not_enough, remainder, _} ->
        pay_off_cc(bulk_invoice, school_context, remainder)

      {:error, :balance_is_empty} ->
        pay_off_cc(bulk_invoice, school_context, total_amount_due)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp pay_off_cc(bulk_invoice, school_context, amount \\ nil) do
    amount = amount || bulk_invoice.total_amount_due

    transaction_attrs =
      transaction_attributes(bulk_invoice)
      |> Map.merge(%{type: "credit", total: amount, payment_option: :cc})

    case PayOff.credit_card(bulk_invoice.user, transaction_attrs, school_context) do
      {:ok, _} -> BulkInvoice.paid_by_cc(bulk_invoice)
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp pay_off_manually(bulk_invoice, school_context) do
    transaction_attrs = transaction_attributes(bulk_invoice)

    case PayOff.manually(bulk_invoice.user, transaction_attrs, school_context) do
      {:ok, _} -> BulkInvoice.paid(bulk_invoice)
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp transaction_attributes(bulk_invoice) do
    %{
      total: bulk_invoice.total_amount_due,
      payment_option: bulk_invoice.payment_option,
      payer_name: User.full_name(bulk_invoice.user),
      bulk_invoice_id: bulk_invoice.id
    }
  end

  defp school(school_context) do

    Flight.SchoolScope.get_school(school_context)
  end

  defp update_invoices(ids, update) do
    from(i in Invoice, select: i, where: i.id in ^ids)
    |> Repo.update_all(set: update)
  end
end
