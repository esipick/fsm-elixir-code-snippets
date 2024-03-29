defmodule Flight.Bills.Queries do
    import Ecto.Query, warn: false

    alias Flight.Billing.{Invoice, InvoiceLineItem}
    alias Flight.Billing.Transaction

    def get_appointment_invoice_aircraft_query(appointment_id, aircraft_id) do
        from i in Invoice,
            inner_join: il in InvoiceLineItem, on: il.invoice_id == i.id and il.aircraft_id == ^aircraft_id,
            select: il,
            where: i.appointment_id == ^appointment_id and i.is_visible == ^true
    end

    def archive_appointment_invoices_query(apmnt_id) do
        query = 
            from i in Invoice

        filter_by(query, %{appointment_id: apmnt_id, status: :pending})
    end

    def select_transactions_query(filter) do
        query = 
            from t in Transaction,
                select: t

        filter_by(query, filter)
    end

    def get_invoices_query(filter) do
        query = 
            from i in Invoice,
                select: i

        filter_by(query, filter)
    end

    defp filter_by(query, nil), do: query 
    defp filter_by(query, filter) do
        filter = 
            Enum.reduce(filter, %{}, fn {key, value}, acc -> 
                if value != nil, do: Map.put(acc, key, value), else: acc 
            end)

        Enum.reduce(filter, query, fn({key, value}, query) -> 
            case key do
                :ids ->
                    from q in query,
                        where: q.id in ^value
                
                :user_id ->
                    from q in query,
                        where: q.user_id == ^value
                
                :invoice_id ->
                    from q in query,
                        where: q.invoice_id == ^value

                :school_id ->
                    from q in query,
                        where: q.school_id == ^value

                :appointment_id ->
                    from q in query,
                        where: q.appointment_id == ^value

                :status ->
                    from q in query,
                        where: q.status == ^value

                :aircraft_id ->
                    from q in query,
                        where: q.aircraft_id == ^value

                :state ->
                    from q in query,
                        where: q.state == ^value

                :id ->
                    from q in query,
                        where: q.id == ^value

                _ -> query
            end
        end)
    end
end