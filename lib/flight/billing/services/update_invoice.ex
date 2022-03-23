defmodule Flight.Billing.UpdateInvoice do
  alias Flight.Repo
  alias Flight.Billing.{Invoice, CreateInvoice, LineItemCreator}
  alias Flight.Scheduling.Aircraft
  alias Flight.Billing.Services.Utils


  def run(invoice, invoice_params, %{assigns: %{current_user: user}} = school_context) do
    send_receipt_email = Map.get(invoice_params, "send_receipt_email")

    pay_off = Map.get(school_context.params, "pay_off", false)
    current_user = school_context.assigns.current_user
    invoice_attribs = invoice_attrs(invoice_params, current_user)
    aircraft_info = Utils.aircraft_info_map(invoice_params)
    checkride_status = Map.get(invoice_params, "appt_status")
    checkride_status =
      checkride_status
      |> case do
        "pass" -> :pass
        "fail" -> :fail
        _ -> :none
      end
    {:ok, invoice_attribs} = Flight.Billing.CalculateInvoice.run(invoice_attribs, school_context)

    {invoice_attribs, update_hours} =
      if Map.get(invoice, :aircraft_info) == nil do
        {Map.put(invoice_attribs, "aircraft_info", aircraft_info), true}

      else
        {invoice_attribs, false}
      end

    line_items = Map.get(invoice_attribs, "line_items") || []

    with {:aircrafts, false} <- Utils.multiple_aircrafts?(line_items),
      {:rooms, false} <- Utils.same_room_multiple_items?(line_items),
      {:ok, invoice} <- update_invoice(invoice, invoice_attribs) do
        Fsm.Scheduling.Appointment.update_check_ride_status(invoice.appointment_id, checkride_status)

        line_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)

        cond do
          invoice.appointment_id != nil -> Utils.update_aircraft(invoice, user)
          update_hours && line_item != nil -> Utils.update_aircraft(line_item.aircraft_id, line_item, user)
          true -> :nothing
        end

        if pay_off == true do
          CreateInvoice.pay(invoice, school_context, send_receipt_email)
        else
          {:ok, invoice}
        end
    else
      {:aircrafts, true} -> {:error, "An invoice can have a single item for Flight, Demo Flight or Simulator Hours."}
      {:rooms, true} -> {:error, "The same room cannot be added twice to an invoice."}
      error -> error
    end
  end

  defp update_invoice(invoice, invoice_params) do
    Invoice.changeset(invoice, invoice_params) |> Repo.update()
  end

  defp invoice_attrs(invoice_params, current_user) do
    case invoice_params["line_items"] do
      nil ->
        invoice_params

      raw_line_items ->
        line_items = LineItemCreator.populate_creator(raw_line_items, current_user)

        Map.merge(invoice_params, %{"line_items" => line_items})
    end
  end

  defp update_aircraft(invoice) do
    line_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)

    if line_item && line_item.hobbs_end && line_item.tach_end do
      aircraft = Repo.get(Aircraft, line_item.aircraft_id)

      {:ok, _} =
        aircraft
        |> Aircraft.changeset(%{
          last_tach_time: max(aircraft.last_tach_time, line_item.tach_end),
          last_hobbs_time: max(aircraft.last_hobbs_time, line_item.hobbs_end)
        })
        |> Flight.Repo.update()
    end
  end
end
