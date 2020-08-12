defmodule Flight.Billing.UpdateInvoice do
  alias Flight.Repo
  alias Flight.Billing.{Invoice, CreateInvoice, LineItemCreator}
  alias Flight.Scheduling.Aircraft
  alias Flight.Billing.Services.Utils


  def run(invoice, invoice_params, %{assigns: %{current_user: user}} = school_context) do
    pay_off = Map.get(school_context.params, "pay_off", false)
    current_user = school_context.assigns.current_user
    invoice_attribs = invoice_attrs(invoice_params, current_user)
    
    line_items = Map.get(invoice_attribs, "line_items") || []

    with false <- Utils.multiple_aircrafts?(line_items), 
      {:ok, invoice} <- update_invoice(invoice, invoice_attribs) do
        if invoice.appointment_id != nil do
          Utils.update_aircraft(invoice, user)
        end

        if pay_off == true do
          CreateInvoice.pay(invoice, school_context)
        else
          {:ok, invoice}
        end
    else
      true -> {:error, "An invoice can have only 1 aircraft hours."}
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
