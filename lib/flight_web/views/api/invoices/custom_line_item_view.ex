defmodule FlightWeb.API.Invoices.CustomLineItemView do
  use FlightWeb, :view

  def render("custom_line_item.json", %{custom_line_item: custom_line_item}) do
    %{
      default_rate: custom_line_item.default_rate,
      description: custom_line_item.description,
      id: custom_line_item.id,
      school_id: custom_line_item.school_id,
      taxable: custom_line_item.taxable
    }
  end
end
