defmodule Flight.InvoiceEmail do
    require EEx
    EEx.function_from_file(:def, :render, Path.expand("./priv/email_templates/templates/invoice.html.eex"), [:assigns])
end

# Flight.Billing.CreateInvoice.send_invoice_email