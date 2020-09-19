defmodule Flight.Billing.CreateInvoice do
  import Ecto.Query

  alias Flight.Repo
  alias Flight.Accounts.User
  alias Flight.Billing.{Invoice, LineItemCreator, PayOff}
  alias FlightWeb.Billing.InvoiceStruct
  alias Flight.Scheduling.{Appointment}
  alias Flight.Billing.Services.Utils
  alias Flight.Billing.TransactionLineItem
  alias Flight.Billing.InvoiceLineItem

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

    with {:aircrafts, false} <- Utils.multiple_aircrafts?(line_items),
        {:rooms, false} <- Utils.same_room_multiple_items?(line_items),
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
      {:aircrafts, true} -> {:error, "An invoice can have a single item for Flight or Simulator Hours."}
      {:rooms, true} -> {:error, "The same room cannot be added twice to an invoice."}
      error -> error
    end
  end

  def pay(invoice, school_context) do
    invoice
    |> Repo.preload(user: from(i in User, lock: "FOR UPDATE NOWAIT"))
    |> Repo.preload(:appointment)
    |> process_payment(school_context)
    |> case do
      {:ok, invoice} ->
        # here make transaction line items and insert.        
        if invoice.appointment && invoice.status == :paid do
          Appointment.paid(invoice.appointment)
        end

        insert_transaction_line_items(invoice, school_context)
        
        if invoice.user_id do
          Flight.InvoiceEmail.send_paid_invoice_email(invoice, school_context)
        end

        {:ok, invoice}

      {:error, changeset} ->
        {:error, changeset}
    end

  end

  defp process_payment(%{total_amount_due: due_amount} = invoice, _school_context) when due_amount <= 0 do
    Invoice.paid(invoice)
  end

  defp process_payment(invoice, school_context) do
    x_device = Enum.into(Map.get(school_context, :req_headers) || [], %{})
    x_device = x_device["X-Device"] || x_device["x-device"] || ""
    x_device = String.downcase(x_device)

    case invoice.payment_option do
      :balance -> pay_off_balance(invoice, school_context)
      :cc -> pay_off_cc(invoice, school_context, x_device)
      _ -> pay_off_manually(invoice, school_context)
    end
  end

  defp pay_off_balance(%Invoice{appointment: %Appointment{demo: true}}, _context) do
    {:error, "Payment method not available for demo flights."}
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
        pay_off_cc(invoice, school_context, nil, remainder)

      {:error, :balance_is_empty} ->
        pay_off_cc(invoice, school_context, nil, total_amount_due)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp pay_off_cc(%Invoice{appointment: %Appointment{demo: true}} = invoice, 
    %{assigns: %{current_user: %{school_id: school_id}}} = school_context, "ios") do
    Flight.StripeSinglePayment.get_payment_intent_secret(invoice, school_id)
    |> case do
      {:ok, %{intent_id: id} = session} -> 
        transaction_attrs = transaction_attributes(invoice)
        CreateTransaction.run(invoice.user, school_context, transaction_attrs)

        Invoice.save_invoice(invoice, %{session_id: id})
        {:ok, Map.merge(invoice, session)}

      error -> error
    end
  end

  defp pay_off_cc(%Invoice{appointment: %Appointment{demo: true}} = invoice, 
    %{assigns: %{current_user: %{school_id: school_id}}} = school_context, _) do
    Flight.StripeSinglePayment.get_stripe_session(invoice, school_id)
    |> case do
      {:ok, session} -> 
        transaction_attrs = transaction_attributes(invoice)
        CreateTransaction.run(invoice.user, school_context, transaction_attrs)

        Invoice.save_invoice(invoice, session)
        {:ok, Map.merge(invoice, session)}

      error -> error
    end
  end

  defp pay_off_cc(invoice, school_context, _, amount \\ nil) do
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

  defp get_invoice_line_items([]), do: []
  defp get_invoice_line_items(invoice_ids) do
    from(ili in InvoiceLineItem, select: ili, where: ili.invoice_id in ^invoice_ids)
    |> Repo.all
  end

  def insert_bulk_invoice_line_items(_, [], _school_context), do: {:ok, :done}
  def insert_bulk_invoice_line_items(%{id: bulk_invoice_id} = bulk_invoice, invoices, school_context) do
    ids = Enum.map(invoices, & &1.id)
    line_items_map = 
      get_invoice_line_items(ids)
      |> Enum.group_by(& &1.invoice_id)

    Enum.map(invoices, fn invoice ->
      line_items = Map.get(line_items_map, invoice.id)
      invoice =
        invoice 
        |> Map.from_struct
        |> Map.put(:line_items, line_items)

      transaction = Flight.Queries.Transaction.get_bulk_invoice_transaction(bulk_invoice_id)
      insert_transaction_line_items(invoice, school_context, transaction)
    end)

    Flight.InvoiceEmail.send_paid_bulk_invoice_email(bulk_invoice, invoices, line_items_map, school_context)

    {:ok, :done}
  end

  defp insert_transaction_line_items(invoice, school_context, transaction \\ nil) do
    aircraft = Enum.find(invoice.line_items, &(&1.aircraft_id != nil && &1.type == :aircraft))
    instructor = Enum.find(invoice.line_items, &(&1.instructor_user_id != nil && &1.type == :instructor))
    
    create_transaction_items(aircraft, instructor, invoice, school_context, transaction)
  end

  defp create_transaction_items(aircraft, instructor, invoice, school_context, transaction \\ nil)
  defp create_transaction_items(aircraft, instructor, _, _, _) when is_nil(aircraft) and is_nil(instructor), do: nil
  defp create_transaction_items(aircraft, instructor, %{id: invoice_id, tax_rate: tax_rate}, school_context, transaction) do

    {_, instructor_line_item, instructor_details, aircraft_line_item, aircraft_details} = 
      %{tax_rate: tax_rate}
      |> aircraft_details(aircraft)
      |> instructor_details(instructor)
      |>  FlightWeb.API.DetailedTransactionForm.to_transaction(:normal, school_context)

    transaction = transaction || Flight.Queries.Transaction.get_invoice_transaction(invoice_id)
    
    with %{id: id} <- transaction do
      insert_instructor_transaction_item(instructor_line_item, instructor_details, id)
      insert_aircraft_transaction_item(aircraft_line_item, aircraft_details, id)
    end
  end

  defp insert_instructor_transaction_item(nil, _item_details, _transaction_id), do: {:ok, %{}}
  defp insert_instructor_transaction_item(item, item_details, transaction_id) do
      item
      |> TransactionLineItem.changeset(%{transaction_id: transaction_id})
      |> Repo.insert
      |> case do
        {:ok, %{id: id}} ->
            item_details
            |> Flight.Billing.InstructorLineItemDetail.changeset(%{transaction_line_item_id: id})
            |> Repo.insert

        error -> error
      end
  end

  defp insert_aircraft_transaction_item(nil, _item_details, _transaction_id), do: {:ok, %{}}
  defp insert_aircraft_transaction_item(item, item_details, transaction_id) do
      item
      |> TransactionLineItem.changeset(%{transaction_id: transaction_id})
      |> Repo.insert
      |> case do
        {:ok, %{id: id}} ->
            item_details
            |> Flight.Billing.AircraftLineItemDetail.changeset(%{transaction_line_item_id: id})
            |> Repo.insert

        error -> error
      end
  end

  defp aircraft_details(form, nil), do: form
  defp aircraft_details(form, line_item) do
    details = %{
      aircraft_id: line_item.aircraft_id,
      hobbs_start: line_item.hobbs_start,
      hobbs_end: line_item.hobbs_end,
      tach_start: line_item.tach_start,
      tach_end: line_item.tach_end,
      rate_per_hour: line_item.rate,
      block_rate_per_hour: 0,
      taxable: line_item.taxable
    }

    Map.put(form, :aircraft_details, details)
  end

  defp instructor_details(form, nil), do: form
  defp instructor_details(form, line_item) do
    details = %{
      instructor_id: line_item.instructor_user_id,
      billing_rate: line_item.rate,
      hour_tenths: Flight.Format.tenths_from_hours(line_item.quantity),
      pay_rate: 0,
      taxable: line_item.taxable
    }

    Map.put(form, :instructor_details, details)
  end
end
