defmodule FlightWeb.Billing.InvoiceController do
  use FlightWeb, :controller

  alias Flight.{Auth.InvoicePolicy, Repo}
  alias Flight.Billing.{Invoice, InvoiceCustomLineItem}
  alias FlightWeb.{Pagination, Billing.InvoiceStruct}

  plug(:get_invoice when action in [:edit, :show, :delete])
  plug(:authorize_modify when action in [:new, :edit, :delete])
  plug(:authorize_view when action in [:show])
  plug(:check_paid_invoice when action in [:update, :edit, :delete])
  plug(:check_archived_invoice when action in [:show, :edit, :update, :delete])

  def index(conn, params) do
    page_params = Pagination.params(params)
    user = conn.assigns.current_user

    page =
      if InvoicePolicy.create?(user) do
        Flight.Queries.Invoice.page(conn, page_params, params)
      else
        options = %{user_id: user.id}
        Flight.Queries.Invoice.own_invoices(conn, page_params, options)
      end

    invoices = page |> Enum.map(fn invoice -> InvoiceStruct.build(invoice) end)

    render(conn, "index.html", page: page, invoices: invoices, params: params)
  end

  def new(conn, _) do
    custom_line_items =
      InvoiceCustomLineItem.get_custom_line_items(conn)
      |> Enum.map(fn custom_line_item ->
        %{
          default_rate: custom_line_item.default_rate,
          description: custom_line_item.description,
          taxable: custom_line_item.taxable
        }
      end)

    props = %{
      custom_line_items: custom_line_items,
      tax_rate: conn.assigns.current_user.school.sales_tax || 0,
      action: "create",
      creator: %{id: conn.assigns.current_user.id}
    }

    render(conn, "new.html", props: props)
  end

  def edit(conn, _) do
    custom_line_items =
      InvoiceCustomLineItem.get_custom_line_items(conn)
      |> Enum.map(fn custom_line_item ->
        %{
          default_rate: custom_line_item.default_rate,
          description: custom_line_item.description
        }
      end)

    props = %{
      action: "edit",
      custom_line_items: custom_line_items,
      id: conn.assigns.invoice.id,
      creator: %{id: conn.assigns.current_user.id}
    }

    render(conn, "edit.html", props: props, skip_shool_select: true)
  end

  def show(conn, _) do
    invoice = InvoiceStruct.build(conn.assigns.invoice)

    render(conn, "show.html", invoice: invoice, skip_shool_select: true)
  end

  def delete(conn, _) do
    conn.assigns.invoice
    |> Invoice.changeset(%{archived: true})
    |> Repo.update()

    conn
    |> put_flash(:success, "Invoice was successfully deleted.")
    |> redirect(to: "/billing/invoices")
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

  defp authorize_modify(conn, _) do
    invoice = if conn.params["id"], do: conn.assigns.invoice, else: nil
    user = conn.assigns.current_user

    cond do
      InvoicePolicy.modify?(user, invoice) ->
        conn

      InvoicePolicy.create?(conn.assigns.current_user) ->
        conn
        |> put_flash(:error, "Can't modify invoice that is already paid.")
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

  defp check_paid_invoice(%{assigns: %{invoice: %{status: :paid}}} = conn, _) do
    conn
    |> put_flash(:error, "Can't modify invoice that is already paid.")
    |> redirect(to: "/billing/invoices/#{conn.assigns.invoice.id}")
  end

  defp check_paid_invoice(conn, _) do
    conn
  end

  defp check_archived_invoice(%{assigns: %{invoice: %{archived: true}}} = conn, _) do
    conn
    |> put_flash(:error, "Invoice has already been removed.")
    |> redirect(to: "/billing/invoices")
  end

  defp check_archived_invoice(conn, _) do
    conn
  end
end
