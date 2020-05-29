defmodule Flight.Billing.CreateInvoice do
  import Ecto.Query

  alias Flight.Repo
  alias Flight.Accounts.User
  alias Flight.Billing.{Invoice, LineItemCreator, PayOff}
  alias FlightWeb.Billing.InvoiceStruct
  alias Flight.Scheduling.{Appointment, Aircraft}

  def run(invoice_params, school_context) do
    pay_off = Map.get(school_context.params, "pay_off", false)
    school = Flight.SchoolScope.get_school(school_context)
    current_user = school_context.assigns.current_user

    line_items = LineItemCreator.populate_creator(invoice_params["line_items"], current_user)

    invoice_attrs =
      Map.merge(
        invoice_params,
        %{
          "school_id" => school.id,
          "tax_rate" => school.sales_tax || 0,
          "line_items" => line_items
        }
      )

    case Invoice.create(invoice_attrs) do
      {:ok, invoice} ->
        update_aircraft(invoice)

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

        {:ok, invoice}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp update_aircraft(invoice) do
    line_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)

    if line_item && line_item.hobbs_end && line_item.tach_end do
      aircraft = Repo.get(Aircraft, line_item.aircraft_id)

      {:ok, _} =
        aircraft
        |> Aircraft.changeset(%{
          last_tach_time: line_item.tach_end,
          last_hobbs_time: line_item.hobbs_end
        })
        |> Flight.Repo.update()
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
    total_amount_due = InvoiceStruct.build(invoice).amount_remainder

    transaction_attrs =
      transaction_attributes(invoice)
      |> Map.merge(%{total: total_amount_due})

    case PayOff.balance(invoice.user, transaction_attrs, school_context) do
      {:ok, :balance_enough, _} ->
        Invoice.paid(invoice)

      {:ok, :balance_not_enough, remainder, _} ->
        pay_off_cc(invoice, school_context, remainder)

      {:error, :balance_is_empty} ->
        pay_off_cc(invoice, school_context, total_amount_due)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp pay_off_cc(invoice, school_context, amount \\ nil) do
    amount = amount || invoice.total_amount_due

    transaction_attrs =
      transaction_attributes(invoice)
      |> Map.merge(%{type: "credit", total: amount, payment_option: :cc})

    case PayOff.credit_card(invoice.user, transaction_attrs, school_context) do
      {:ok, _} -> Invoice.paid_by_cc(invoice)
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp pay_off_manually(invoice, school_context) do
    transaction_attrs = transaction_attributes(invoice)

    case PayOff.manually(invoice.user, transaction_attrs, school_context) do
      {:ok, _} -> Invoice.paid(invoice)
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp transaction_attributes(invoice) do
    %{
      total: invoice.total_amount_due,
      payment_option: invoice.payment_option,
      payer_name: invoice.payer_name,
      invoice_id: invoice.id
    }
  end
end
