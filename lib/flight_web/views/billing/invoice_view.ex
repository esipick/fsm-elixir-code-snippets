defmodule FlightWeb.Billing.InvoiceView do
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

  def line_item_notes(line_item) do
    line_item = Flight.Repo.preload(line_item, [:instructor_user, :aircraft])

    case line_item.type do
      :instructor ->
        if line_item.instructor_user do
          name = Flight.Accounts.User.full_name(line_item.instructor_user)
          "Instructor: #{name}"
        else
          ""
        end
      :aircraft ->
        if line_item.aircraft do
          "Tail #: #{line_item.aircraft.tail_number}"
        else
          ""
        end
      _ -> ""
    end
  end
end
