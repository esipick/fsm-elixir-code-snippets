defmodule FlightWeb.API.Invoices.LineItemView do
  use FlightWeb, :view

  def render("extra_options.json", %{custom_line_items: custom_line_items}) do
    %{
      data:
        for custom_line_item <- custom_line_items do
          %{
            default_rate: custom_line_item.default_rate,
            description: custom_line_item.description,
            taxable: custom_line_item.taxable,
            deductible: custom_line_item.deductible
          }
        end
    }
  end
end
