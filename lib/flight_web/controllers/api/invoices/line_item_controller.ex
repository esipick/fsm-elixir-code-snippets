defmodule FlightWeb.API.Invoices.LineItemController do
  use FlightWeb, :controller

  alias Flight.Auth.Permission
  alias FlightWeb.{ViewHelpers}

  plug(:authorize_view)

  def extra_options(conn, _) do
    render(conn, "extra_options.json")
  end

  defp authorize_view(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:invoice, :modify, :all)])
  end
end
