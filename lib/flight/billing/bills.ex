defmodule Flight.Bills do
    alias Flight.Bills.Queries
    # alias Flight.Billing.{Invoice, InvoiceLineItem}
    alias Flight.{
        Repo,
        InvoiceEmail,
        InvoiceUploader
    }

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

    def archive_appointment_invoices(appointment_id) do
        archived_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    
        appointment_id
        |> Queries.archive_appointment_invoices_query
        |> Repo.update_all(set: [archived: true, archived_at: archived_at])
    end

    def get_invoice(id, school_id) do
        %{
            id: id,
            school_id: school_id
        }
        |> Queries.get_invoices_query
        |> Repo.get_by([])
        |> case do
            nil -> {:error, "Invoice with id: #{id} not found."}
            invoice -> {:ok, invoice}
        end
    end

    def get_invoice_url(id, school_id) do
        school = Flight.SchoolScope.get_school(%{school_id: school_id})

        with {:ok, invoice} <- get_invoice(id, school_id),
            invoice <- Map.from_struct(FlightWeb.Billing.InvoiceStruct.build(invoice)),
            {:ok, pdf_path} <- InvoiceEmail.convert_to_pdf(invoice, school),
            {:ok, _} <- InvoiceUploader.store({pdf_path, id}) do
                File.rm(pdf_path)
                file_name = Path.basename(pdf_path)
                url = InvoiceUploader.url({file_name, id})
                {:ok, url}
        else
            {:error, error} -> {:error, error}
            _ -> {:error, "Couldn't print invoice for id: #{id}"}
        end
    end
end