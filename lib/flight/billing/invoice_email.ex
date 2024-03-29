defmodule Flight.InvoiceEmail do
    require EEx
    EEx.function_from_file(:def, :render, Path.expand("./priv/email_templates/templates/invoice.html.eex"), [:assigns])

    def send_paid_invoice_email(invoice, school_context) do
        school = Flight.SchoolScope.get_school(school_context)

        invoice
        |> FlightWeb.Billing.InvoiceStruct.build()
        |> Map.from_struct
        |> deliver_email(school)
      end

    def send_paid_bulk_invoice_email(bulk_invoice, invoices, line_items_map, school_context) do
        user = Flight.Accounts.dangerous_get_user(bulk_invoice.user_id)
        school = Flight.SchoolScope.get_school(school_context)

        payment_date =
        NaiveDateTime.utc_now()
        |> Flight.Walltime.utc_to_walltime(school.timezone)
        |> NaiveDateTime.to_date

        invoice_calc =
        Enum.reduce(invoices, %{}, fn invoice, acc ->
            total = Map.get(acc, :total) || 0
            total_tax = Map.get(acc, :total_tax) || 0
            amount_due = Map.get(acc, :amount_due) || 0

            acc
            |> Map.put(:total, total + invoice.total)
            |> Map.put(:total_tax, total_tax + invoice.total_tax)
            |> Map.put(:amount_due, amount_due + invoice.total_amount_due)
            |> Map.put(:amount_paid, amount_due + invoice.total_amount_due)
            |> Map.put(:amount_remainder, 0)
        end)

        %{
        user: user,
        id: bulk_invoice.id,
        payment_date: payment_date,
        payer_name: user.first_name <> " " <> user.last_name,
        line_items: List.flatten(Map.values(line_items_map)),
        }
        |> Map.merge(invoice_calc)
        |> deliver_email(school)
    end

    def deliver_email(invoice, school) do
        # We need to get an email from invoice.payer_email
        # in case of guest, demo user othervise from user.email
        #
        # We're sure that for guest, demo user_id would be empty so
        # consider getting payer_email instead of invoice.user.email
        email = if  is_nil(invoice.user_id), do: invoice.payer_email, else: invoice.user.email

        # For guest, demo user is optional we have to apply a check where as well
        case is_nil(email) or !String.match?(email, ~r/^\S+@\S+\.\S+$/) or email == "" do
          true ->
            {:error, "Recipient email doesn't exist"}
          false ->
            Mondo.Task.start(fn ->
                with {:ok, pdf_path} <- convert_to_pdf(invoice, school) do
                    email
                    |> Flight.Email.invoice_email(invoice.id, pdf_path)
                    |> Flight.Mailer.deliver_now

                    File.rm!(pdf_path)
                end
            end)
        end
    end

    def convert_to_pdf(invoice, school) do
        assigns = %{
            school: school,
            base_url: Application.get_env(:flight, :web_base_url),
            invoice: invoice
        }

        with true <- Enum.count(invoice.line_items) > 0,
            html <- Flight.InvoiceEmail.render(assigns) do
                pdf_from_html(invoice.id, html)
        end
    end

    def pdf_from_html(id, html) do
        options = [format: "A4", print_background: true]
        pdf_path = Path.absname("#{id}-invoice.pdf")
        IO.inspect("pdf_path #{inspect pdf_path}")
        IO.inspect("html: #{inspect html}")
        case PuppeteerPdf.Generate.from_string(html, pdf_path, options) do
            {:ok, _} ->
                IO.inspect("pdf_path11: #{inspect pdf_path}")
                {:ok, pdf_path}
            {:error, message} ->
                IO.inspect("message: #{inspect message}")
        end
    end
end
