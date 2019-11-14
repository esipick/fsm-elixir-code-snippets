defmodule FlightWeb.Billing.TransactionView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers
  import Scrivener.HTML
  alias Flight.Auth.InvoicePolicy

  def can_modify_invoice?(conn, invoice) do
    InvoicePolicy.modify?(conn.assigns.current_user, invoice)
  end

  def can_create_invoice?(conn) do
    InvoicePolicy.create?(conn.assigns.current_user)
  end
end
