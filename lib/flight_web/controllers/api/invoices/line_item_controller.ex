defmodule FlightWeb.API.Invoices.LineItemController do
  use FlightWeb, :controller

  def extra_options(conn, _) do
    custom_line_items = Flight.Billing.InvoiceCustomLineItem.get_custom_line_items(conn)
    render(conn, "extra_options.json", custom_line_items: custom_line_items)
  end
end
