defmodule Flight.Billing.UpdateInvoice do
  alias Flight.Repo
  alias Flight.Billing.{Invoice, CreateInvoice, LineItemCreator}
  alias Flight.Scheduling.Aircraft

  def run(invoice, invoice_params, school_context) do
    pay_off = Map.get(school_context.params, "pay_off", false)
    current_user = school_context.assigns.current_user

    result =
      case update_invoice(invoice, invoice_attrs(invoice_params, current_user)) do
        {:ok, invoice} ->
          update_aircraft(invoice)

          if pay_off == true do
            CreateInvoice.pay(invoice, school_context)
          else
            {:ok, invoice}
          end

        {:error, error} ->
          {:error, error}
      end

    result
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
