defmodule FlightWeb.Admin.BillingController do
  use FlightWeb, :controller

  alias FlightWeb.Endpoint
  alias FlightWeb.Router.Helpers, as: Routes

  def index(conn, _) do
    redirect(conn, to: Routes.billing_invoice_path(Endpoint, :index))
  end
end
