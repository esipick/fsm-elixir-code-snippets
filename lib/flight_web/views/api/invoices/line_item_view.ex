defmodule FlightWeb.API.Invoices.LineItemView do
  use FlightWeb, :view

  def render("extra_options.json", _) do
    %{
      data: [
        %{description: "Fuel Charge", default_rate: 100},
        %{description: "Fuel Reimbursement", default_rate: 100},
        %{description: "Equipment Rental", default_rate: 100}
      ]
    }
  end
end
