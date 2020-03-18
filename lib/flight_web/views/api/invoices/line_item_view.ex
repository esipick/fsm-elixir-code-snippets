defmodule FlightWeb.API.Invoices.LineItemView do
  use FlightWeb, :view

  def render("extra_options.json", %{current_user: user}) do
    custom_line_items =
      Flight.Billing.InvoiceCustomLineItem
      |> Flight.SchoolScope.scope_query(user)
      |> Flight.Repo.all()

    %{
      data:
        for custom_line_item <- custom_line_items do
          %{
            default_rate: custom_line_item.default_rate,
            description: custom_line_item.description
          }
        end
    }
  end
end
