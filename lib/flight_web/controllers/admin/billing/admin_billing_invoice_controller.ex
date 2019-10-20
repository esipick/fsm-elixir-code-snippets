defmodule FlightWeb.Admin.Billing.InvoiceController do
  use FlightWeb, :controller

  import Ecto.Query

  alias Flight.{Repo, Billing.Invoice}
  alias FlightWeb.{Pagination, Admin.Billing.InvoiceStruct}

  plug(:get_invoice when action in [:edit])

  def index(conn, params) do
    page_params = Pagination.params(params)
    page = from(i in Invoice) |> Repo.paginate(page_params)
    invoices = page |> Enum.map(fn invoice -> InvoiceStruct.build(invoice) end)

    render(conn, "index.html", page: page, invoices: invoices)
  end

  def new(conn, _) do
    props = %{
      tax_rate: conn.assigns.current_user.school.sales_tax || 25,
      action: "create"
    }

    render(conn, "new.html", props: props)
  end

  def edit(conn, _) do
    props = Invoice.get_edit_props(conn.assigns.invoice)

    render(conn, "edit.html", props: props)
  end

  defp get_invoice(conn, _) do
    invoice = Repo.get(Invoice, conn.params["id"])

    if invoice do
      assign(conn, :invoice, invoice)
    else
      conn
      |> send_resp(404, "")
      |> halt()
    end
  end
end
