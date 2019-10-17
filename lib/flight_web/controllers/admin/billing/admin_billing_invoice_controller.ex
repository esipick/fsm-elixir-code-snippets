defmodule FlightWeb.Admin.Billing.InvoiceController do
  use FlightWeb, :controller

  import Ecto.Query

  alias Flight.{Repo, Billing.Invoice}
  alias FlightWeb.{Pagination, Admin.Billing.InvoiceStruct}

  def index(conn, params) do
    page_params = Pagination.params(params)
    page = from(i in Invoice) |> Repo.paginate(page_params)
    invoices = page |> Enum.map(fn invoice -> InvoiceStruct.build(invoice) end)

    render(conn, "index.html", page: page, invoices: invoices)
  end
end
