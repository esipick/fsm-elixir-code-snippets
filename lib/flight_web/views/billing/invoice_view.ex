defmodule FlightWeb.Billing.InvoiceView do
  use FlightWeb, :view

  import FlightWeb.ViewHelpers
  import Scrivener.HTML

  alias Flight.Auth.{Authorization, InvoicePolicy, Permission}

  def can_modify_invoice?(conn, invoice) do
    InvoicePolicy.modify?(conn.assigns.current_user, invoice)
  end

  def can_send_invoice?(conn, invoice) do
    InvoicePolicy.send_invoice?(conn.assigns.current_user, invoice)
  end

  def can_send_bulk_invoice?(conn) do
    InvoicePolicy.can_send_bulk_invoice?(conn.assigns.current_user)
  end

  def can_delete_invoice?(conn, invoice) do
    InvoicePolicy.delete?(conn.assigns.current_user, invoice)
  end

  def can_create_bulk_invoice?(conn) do
    Authorization.user_can?(conn.assigns.current_user, [
      Permission.new(:bulk_invoice, :modify, :all)
    ])
  end

  def line_item_notes(line_item) do
    line_item = Flight.Repo.preload(line_item, [:instructor_user, :aircraft, :room])

    cond do
      line_item.type == :instructor && line_item.instructor_user ->
        "Instructor: #{Flight.Accounts.User.full_name(line_item.instructor_user)}"

      line_item.type == :aircraft && line_item.aircraft ->
        "Tail #: #{line_item.aircraft.tail_number}"
      
      line_item.type == :other && line_item.room ->
        "Room #: #{inspect line_item.room.location}"
        
      true ->
        ""
    end
  end

  def deductible_class(line_item) do
    if line_item.deductible do
      "deductible"
    else
      ""
    end
  end
end
