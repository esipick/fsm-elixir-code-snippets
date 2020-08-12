defmodule Flight.Billing.CreateInvoice do
  import Ecto.Query

  alias Flight.Repo
  alias Flight.Accounts.User
  alias Flight.Billing.{Invoice, LineItemCreator, PayOff}
  alias FlightWeb.Billing.InvoiceStruct
  alias Flight.Scheduling.{Appointment}
  alias Flight.Billing.Services.Utils

  def run(invoice_params, %{assigns: %{current_user: user}} = school_context) do
    pay_off = Map.get(school_context.params, "pay_off", false)
    school = Flight.SchoolScope.get_school(school_context)
    current_user = school_context.assigns.current_user

    line_items = LineItemCreator.populate_creator(invoice_params["line_items"], current_user)
    aircraft_info = Utils.aircraft_info_map(invoice_params)

    invoice_attrs =
      Map.merge(
        invoice_params,
        %{
          "school_id" => school.id,
          "tax_rate" => school.sales_tax || 0,
          "line_items" => line_items,
          "aircraft_info" => aircraft_info
        }
      )

    with false <- Utils.multiple_aircrafts?(line_items),
        {:ok, invoice} <- Invoice.create(invoice_attrs) do
          line_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)

          cond do
            invoice.appointment_id != nil -> Utils.update_aircraft(invoice, user)
            line_item != nil -> Utils.update_aircraft(line_item.aircraft_id, line_item, user)
            true -> :nothing
          end
  
          if pay_off == true do
            case pay(invoice, school_context) do
              {:ok, invoice} -> {:ok, invoice}
              {:error, error} -> {:error, invoice.id, error}
            end
          else
            {:ok, invoice}
          end  
    else
      true -> {:error, "An invoice can have only 1 aircraft hours."}
      error -> error
    end
  end

  def pay(invoice, school_context) do
    invoice =
      Repo.preload(invoice, user: from(i in User, lock: "FOR UPDATE NOWAIT"))
      |> Repo.preload(:appointment)

    IO.inspect(invoice, label: "Invoice.")

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
