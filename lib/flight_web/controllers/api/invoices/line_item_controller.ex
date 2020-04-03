defmodule FlightWeb.API.Invoices.LineItemController do
  use FlightWeb, :controller

  alias Flight.Auth.Permission

  plug(:authorize_view)

  def extra_options(conn, _) do
    user = conn.assigns.current_user

    custom_line_items =
      Flight.Billing.InvoiceCustomLineItem
      |> Flight.SchoolScope.scope_query(user)
      |> Flight.Repo.all()
      |> Enum.sort_by(& &1.inserted_at)

    render(conn, "extra_options.json", custom_line_items: custom_line_items)
  end

  defp authorize_view(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:invoice, :modify, :all)])
  end
end
