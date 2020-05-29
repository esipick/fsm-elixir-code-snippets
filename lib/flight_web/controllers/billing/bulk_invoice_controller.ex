defmodule FlightWeb.Billing.BulkInvoiceController do
  use FlightWeb, :controller

  import Flight.Auth.Authorization

  alias Flight.Auth.Permission

  plug(:authorize_modify when action in [:new])

  def new(conn, _) do
    props = %{}

    render(conn, "new.html", props: props)
  end

  defp authorize_modify(conn, _) do
    user = conn.assigns.current_user

    if user_can?(user, [Permission.new(:bulk_invoice, :modify, :all)]) do
      conn
    else
      redirect_unathorized_user(conn)
    end
  end
end
