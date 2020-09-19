defmodule FlightWeb.Billing.BulkInvoiceController do
  use FlightWeb, :controller

  import Flight.Auth.Authorization

  alias Flight.Auth.Permission

  plug(:authorize_modify when action in [:new])

  # TODO:
  # 1 - Mass payment for anonymous users
  def new(conn, _) do
    props = %{}

    render(conn, "new.html", props: props)
  end

  def send_bulk_invoice(conn, params) do
    success = Map.get(params, "success")

    if success == "1" do
      put_flash(conn, :success, "Bulk Invoice email Successfully sent.")
      |> redirect(to: "/billing/bulk_invoices/send_bulk_invoice")

    else
      render(conn, "send_bulk_invoice.html", props: %{})
    end
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
