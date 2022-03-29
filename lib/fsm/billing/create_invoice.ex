defmodule Fsm.Billing.CreateInvoice do
    import Ecto.Query

    alias Flight.Repo
    alias Fsm.Accounts.User
    alias Fsm.Accounts
    alias Fsm.Billing.Invoice
    alias Fsm.Billing.LineItemCreator
    alias Flight.Billing.PayOff
    alias FlightWeb.Billing.InvoiceStruct
    alias Flight.Scheduling.{Appointment}
    alias Flight.Billing.Services.Utils
    alias Flight.Billing.TransactionLineItem
    alias Flight.Billing.InvoiceLineItem

    require Logger

    def run(invoice_params, pay_off, school_id, user_id) do

      ## archive course invoice if there is
      if Map.get(invoice_params, :course_id, false) do
        invoices = Flight.Queries.Invoice.course_invoices_by_course(user_id, Map.get(invoice_params, :course_id))
                   |> Repo.all()

        #Invoice.archive(conn.assigns.invoice)
        Enum.map(invoices, fn (invoice) ->
          Invoice.archive(invoice)
        end)

      end

      pay_off = pay_off || false
      school = Fsm.SchoolScope.get_school(school_id)
      %{roles: _roles, user: current_user} = Accounts.get_user(user_id)
      school_context = %Plug.Conn{assigns: %{current_user: current_user}}
      checkride_status = Map.get(invoice_params,:appt_status)
      #Logger.info fn -> " Map.get(invoice_params, :line_items): #{inspect  Map.get(invoice_params, :line_items) }" end
      line_items =   LineItemCreator.populate_creator(Map.get(invoice_params, :line_items), current_user)

      aircraft_info = Utils.aircraft_info_map(invoice_params)

      invoice_attrs =
        Map.merge(

          invoice_params,
          %{
            school_id: school.id,
            tax_rate: school.sales_tax || 0,
            line_items: line_items,
            aircraft_info: aircraft_info
          }
        )

      send_receipt_email = Map.get(invoice_params, :send_receipt_email)

      with {:aircrafts, false} <- Utils.multiple_aircrafts?(line_items),
          {:rooms, false} <- Utils.same_room_multiple_items?(line_items),
          {:ok, invoice} <- Invoice.create(invoice_attrs) do
            Fsm.Scheduling.Appointment.update_check_ride_status(invoice.appointment_id, checkride_status)

            line_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)

            cond do
              invoice.appointment_id != nil -> Utils.update_aircraft(invoice, current_user)
              line_item != nil -> Utils.update_aircraft(line_item.aircraft_id, line_item,current_user)
              true -> :nothing
            end

            if pay_off == true do
              invoice =
                if Map.get(invoice_params, :stripe_token) not in [nil, ""] do
                  Map.put(invoice, :stripe_token, Map.get(invoice_params, :stripe_token))

                else
                  invoice
                end
              case pay(invoice, school_context, send_receipt_email) do
                {:ok, invoice} ->
                  Invoice.paid(invoice)
                  #If course invoice enroll student at LMS.
                  if Map.get(invoice_params, :course_id, false) do
                    Flight.General.enroll_student(current_user ,Map.get(invoice_params, :course_id) )
                  end
                  {:ok, Map.put(invoice, :appt_status, checkride_status)}
                {:error, error} -> {:error, "Invoice Id:" <> inspect(invoice.id)<> " " <> error.message}
              end
            else
              {:ok, Map.put(invoice, :appt_status, checkride_status)}
            end
      else
        {:aircrafts, true} -> {:error, "An invoice can have a single item for Flight, Demo Flight or Simulator Hours."}
        {:rooms, true} -> {:error, "The same room cannot be added twice to an invoice."}
        error -> error
      end
    end

    def pay(invoice, school_context, send_receipt_email) do
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

          # as a business perspective, we only want to paid
          # the invoice without creating transaction
          if(invoice.payment_option != :maintenance) do
            insert_transaction_line_items(invoice, school_context)
          end

          # As we intend to send email for walk-in purchases (issue # 563),
          # we need to remove check invoice.user_id, because we don't have
          # actual user account for walk-in purchases

          # FROM
          # if invoice.user_id && invoice.status == :paid do
          # TO
          # if invoice.status == :paid do
          # Note: we also have guard conditions

          if invoice.status == :paid and (send_receipt_email == true or send_receipt_email == nil) do
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
        :cc ->
          is_demo = is_demo_invoice?(invoice)
          pay_off_cc(invoice, school_context, is_demo, x_device)

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
          is_demo = is_demo_invoice?(invoice)
          pay_off_cc(invoice, school_context, is_demo, nil, remainder)

        {:error, :balance_is_empty} ->
          is_demo = is_demo_invoice?(invoice)
          pay_off_cc(invoice, school_context, is_demo, nil, total_amount_due)

        {:error, changeset} ->
          {:error, changeset}
      end
    end

    defp pay_off_cc(invoice,
      %{assigns: %{current_user: %{school_id: school_id}}} = school_context, true, "ios") do
      Flight.StripeSinglePayment.get_payment_intent_secret(invoice, school_id)
      |> case do
        {:ok, %{intent_id: id} = session} ->
          Flight.Bills.delete_invoice_pending_transactions(invoice.id, invoice.user_id, school_id)
          transaction_attrs = transaction_attributes(invoice)
          CreateTransaction.run(invoice.user, school_context, transaction_attrs)

          Invoice.save_invoice(invoice, %{session_id: id})
          {:ok, Map.merge(invoice, session)}

        error -> error
      end
    end

    defp pay_off_cc(%{stripe_token: stripe_token} = invoice,
      %{assigns: %{current_user: %{school_id: school_id}}} = school_context, true, _) when not is_nil(stripe_token) do

      Flight.StripeSinglePayment.charge_stripe_token(invoice, school_id)
      |> case do
        {:ok, session} ->
          Flight.Bills.delete_invoice_pending_transactions(invoice.id, invoice.user_id, school_id)
          oldInvoice = invoice
          invoice = Map.merge(invoice, %{payment_option: :cc, status: :paid})
          transaction_attrs = transaction_attributes(invoice)
          transaction_attrs = Map.merge(transaction_attrs, %{state: "completed", completed_at: NaiveDateTime.utc_now()})
          CreateTransaction.run(invoice.user, school_context, transaction_attrs)
          Invoice.save_invoice(oldInvoice,  Map.merge(%{payment_option: :cc, status: :paid},session))
          {:ok, Map.merge(invoice, session)}

        error ->
          error
      end
    end

    defp pay_off_cc(invoice,
      %{assigns: %{current_user: %{school_id: school_id}}} = school_context, true, _) do

      Flight.StripeSinglePayment.get_stripe_session(invoice, school_id)
      |> case do
        {:ok, session} ->
          Flight.Bills.delete_invoice_pending_transactions(invoice.id, invoice.user_id, school_id)
          transaction_attrs = transaction_attributes(invoice)
          CreateTransaction.run(invoice.user, school_context, transaction_attrs)

          Invoice.save_invoice(invoice, session)
          {:ok, Map.merge(invoice, session)}

        error -> error
      end
    end

    defp pay_off_cc(invoice, school_context, _, _, amount \\ nil) do

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
      if(invoice.payment_option == :maintenance) do
        Invoice.paid(invoice)
      else
        case PayOff.manually(invoice.user, transaction_attrs, school_context) do
          {:ok, _} -> Invoice.paid(invoice)
          {:error, changeset} -> {:error, changeset}
        end
      end
    end

    defp transaction_attributes(invoice) do
      %{
        total: invoice.total_amount_due,
        payment_option: invoice.payment_option,
        payer_name: invoice.payer_name,
        payer_email: invoice.payer_email,
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

    def insert_transaction_line_items(invoice, school_context, transaction \\ nil) do
      aircraft = Enum.find(invoice.line_items, &(&1.aircraft_id != nil && &1.type == :aircraft))
      instructor = Enum.find(invoice.line_items, &(&1.instructor_user_id != nil && &1.type == :instructor))

      create_transaction_items(aircraft, instructor, invoice, school_context, transaction)
    end

    # defp create_transaction_items(aircraft, instructor, invoice, school_context, transaction \\ nil)
    defp create_transaction_items(aircraft, instructor, _, _, _) when is_nil(aircraft) and is_nil(instructor), do: nil
    defp create_transaction_items(aircraft, instructor, %{id: invoice_id, tax_rate: tax_rate}, school_context, transaction) do

      {_, instructor_line_item, instructor_details, aircraft_line_item, aircraft_details} =
        %{tax_rate: tax_rate}
        |> aircraft_details(aircraft)
        |> instructor_details(instructor)
        |>  FlightWeb.API.DetailedTransactionForm.to_transaction(:normal, school_context)

      transaction = transaction || Flight.Queries.Transaction.get_invoice_transaction(invoice_id)

      with %{id: id, state: "completed"} <- transaction do
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

    def is_demo_invoice?(%Invoice{appointment: %Appointment{demo: demo}}), do: demo
    def is_demo_invoice?(invoice) do
      demo =
        Enum.find(invoice.line_items, fn item -> item.description == "Demo Flight" end) != nil
      user = Map.get(invoice, :user) || %{}
      has_cc = Map.get(user, :stripe_customer_id) != nil

      if demo && has_cc do
        false

      else
        demo
      end
    end
  end
