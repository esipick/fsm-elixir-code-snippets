defmodule Flight.Bills do
    alias Flight.Bills.Queries
    # alias Flight.Billing.{Invoice, InvoiceLineItem}
    alias Flight.Repo

    def delete_appointment_aircraft(appointment_id, aircraft_id) 
        when is_nil(aircraft_id) or is_nil(appointment_id), do: {:error, "Not found."}
    def delete_appointment_aircraft(appointment_id, aircraft_id) do
        Queries.get_appointment_invoice_aircraft_query(appointment_id, aircraft_id)
        |> Ecto.Query.first
        |> Repo.one
        |> case do
            nil -> {:error, "Not found."}
            line_item ->
                Repo.delete(line_item)
        end
    end
end