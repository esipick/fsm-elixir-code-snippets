defmodule Flight.Bills.Queries do
    import Ecto.Query, warn: false

    alias Flight.Billing.{Invoice, InvoiceLineItem}

    def get_appointment_invoice_aircraft_query(appointment_id, aircraft_id) do
        query = 
        from i in Invoice,
            inner_join: il in InvoiceLineItem, on: il.invoice_id == i.id and il.aircraft_id == ^aircraft_id,
            select: il,
            where: i.appointment_id == ^appointment_id and i.is_visible == ^true
    end

    defp filter_by(query, nil), do: query 
    defp filter_by(query, filter) do
        Enum.reduce(filter, query, fn({key, value}, query) -> 
            case key do
                :aircraft_id ->
                    from q in query,
                        where: q.aircraft_id == ^value

                :id ->
                    from q in query,
                        where: q.id == ^value

                _ -> query
            end
        end)
    end
end