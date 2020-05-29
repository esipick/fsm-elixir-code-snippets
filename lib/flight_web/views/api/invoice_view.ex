defmodule FlightWeb.API.BulkInvoiceView do
  use FlightWeb, :view

  def render("show.json", %{bulk_invoice: bulk_invoice}) do
    %{data: render("bulk_invoice.json", bulk_invoice: bulk_invoice)}
  end

  def render("bulk_invoice.json", %{bulk_invoice: bulk_invoice}) do
    %{id: bulk_invoice.id}
  end
end
