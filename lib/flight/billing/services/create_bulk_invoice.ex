defmodule Flight.Billing.CreateBulkInvoice do
  alias Flight.Accounts.User
  alias Flight.Billing.{BulkInvoice, PayOff}

  def run(invoice_params, school_context) do
    school = school(school_context)
    invoice_attrs = Map.merge(invoice_params, %{"school_id" => school.id})

    case BulkInvoice.create(invoice_attrs) do
      {:ok, bulk_invoice} ->
        case pay(bulk_invoice, school_context) do
          {:ok, bulk_invoice} -> {:ok, bulk_invoice}
          {:error, error} -> {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def pay(bulk_invoice, school_context) do
    case process_payment(bulk_invoice, school_context) do
      {:ok, bulk_invoice} ->
        # TODO: mark all invoices paid

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
end
