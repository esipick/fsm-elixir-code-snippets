defmodule FlightWeb.API.InvoiceLineItemView do
  use FlightWeb, :view

  def render("line_item.json", %{line_item: line_item}) do
    %{
      id: line_item.id,
      rate: line_item.rate,
      amount: line_item.amount,
      quantity: line_item.quantity,
      description: line_item.description,
    }
  end
end
