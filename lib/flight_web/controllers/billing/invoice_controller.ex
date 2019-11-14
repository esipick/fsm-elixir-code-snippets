defmodule FlightWeb.Billing.InvoiceController do
  use FlightWeb, :controller

  alias Flight.{Repo, Billing.Invoice}
  alias FlightWeb.{Pagination, Billing.InvoiceStruct}
  alias Flight.Auth.InvoicePolicy

  plug(:get_invoice when action in [:edit, :show])
  plug(:authorize_modify when action in [:new, :edit])
  plug(:authorize_view when action in [:show])

  def index(conn, params) do
    page_params = Pagination.params(params)
    user = conn.assigns.current_user

    options = if InvoicePolicy.create?(user) do
      %{}
    else
      %{"user_id" => user.id}
    end

    page = Flight.Queries.Invoice.page(conn, page_params, options)
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

  def authorize_modify(conn, _) do
    invoice = conn.assigns.invoice
    user = conn.assigns.current_user

    cond do
      InvoicePolicy.modify?(user, invoice) ->
        conn
      InvoicePolicy.create?(conn.assigns.current_user) ->
        conn
        |> redirect(to: "/billing/invoices/#{conn.assigns.invoice.id}")
      true ->
        redirect_unathorized_user(conn)
    end
  end

  defp authorize_view(conn, _) do
    invoice = conn.assigns.invoice
    user = conn.assigns.current_user

    if InvoicePolicy.view?(user, invoice) do
      conn
    else
      authorize_modify(conn, nil)
    end
  end
end
