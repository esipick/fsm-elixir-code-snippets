defmodule FlightWeb.Admin.Billing.InvoiceController do
  use FlightWeb, :controller

  import Ecto.Query

  alias Flight.{Repo, Billing.Invoice}
  alias FlightWeb.{Pagination, Admin.Billing.InvoiceStruct}

  plug(:get_invoice when action in [:edit, :show])
  plug(:check_paid_invoice when action in [:edit])

  def index(conn, params) do
    page_params = Pagination.params(params)
    page = from(i in Invoice, order_by: [desc: i.inserted_at]) |> Repo.paginate(page_params)
    invoices = page |> Enum.map(fn invoice -> InvoiceStruct.build(invoice) end)

    render(conn, "index.html", page: page, invoices: invoices)
  end

  def new(conn, _) do
    props = %{
      tax_rate: (conn.assigns.current_user.school.sales_tax || 0),
      action: "create"
    }

    render(conn, "new.html", props: props)
  end

  def edit(conn, _) do
    props = Invoice.get_edit_props(conn.assigns.invoice)
    invoice = conn.assigns.invoice

    render(conn, "edit.html", props: props, invoice: invoice)
  end

  def show(conn, _) do
    invoice = InvoiceStruct.build(conn.assigns.invoice)

    render(conn, "show.html", invoice: invoice)
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

  defp check_paid_invoice(conn, _) do
    if conn.assigns.invoice.status == :paid do
      conn
      |> redirect(to: "/admin/billing/invoices/#{conn.assigns.invoice.id}")
    else
      conn
    end
  end
end
