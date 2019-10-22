defmodule FlightWeb.API.InvoiceController do
  use FlightWeb, :controller

  import Ecto.Query

  alias Flight.Repo
  alias Flight.Auth.Permission
  alias FlightWeb.{ViewHelpers, Pagination}
  alias Flight.Billing.{Invoice, CreateInvoice, UpdateInvoice}

  plug(:get_invoice when action in [:update, :show])
  plug(:authorize_modify when action in [:create, :show, :index, :update])
  plug(:check_paid_invoice when action in [:update])

  def index(conn, params) do
    page_params = Pagination.params(params)
    page = from(i in Invoice) |> Repo.paginate(page_params)
    invoices = Repo.preload(page.entries, [:user, :line_items])

    conn
    |> put_status(200)
    |> Scrivener.Headers.paginate(page)
    |> render("index.json", invoices: invoices)
  end

  def create(conn, %{"invoice" => invoice_params}) do
    case CreateInvoice.run(invoice_params, conn) do
      {:ok, invoice} ->
        invoice = Repo.preload(invoice, [:line_items, :user], force: true)

        conn
        |> put_status(201)
        |> render("show.json", invoice: invoice)
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})
      {:error, id, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{id: id, errors: ViewHelpers.translate_errors(changeset)})
      {:error, id, %Stripe.Error{} = error} ->
        conn
        |> put_status(error.extra.http_status)
        |> json(%{id: id, stripe_error: error.message})
    end
  end

  def update(conn, %{"invoice" => invoice_params}) do
    case UpdateInvoice.run(conn.assigns.invoice, invoice_params, conn) do
      {:ok, invoice} ->
        invoice = Repo.preload(invoice, [:line_items, :user], force: true)

        conn
        |> put_status(200)
        |> render("show.json", invoice: invoice)
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})
      {:error, %Stripe.Error{} = error} ->
        conn
        |> put_status(error.extra.http_status)
        |> json(%{stripe_error: error.message})
    end
  end

  def show(conn, _params) do
    invoice = Repo.preload(conn.assigns.invoice, [:line_items, :user], force: true)

    conn
    |> put_status(200)
    |> render("show.json", invoice: invoice)
  end

  defp get_invoice(conn, _) do
    invoice = Repo.get(Invoice, conn.params["id"])
    invoice = Repo.preload(invoice, :line_items)

    if invoice do
      assign(conn, :invoice, invoice)
    else
      conn
      |> send_resp(404, "")
      |> halt()
    end
  end

  defp authorize_modify(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:invoice, :modify, :all)])
  end

  defp check_paid_invoice(conn, _) do
    if conn.assigns.invoice.status == :paid do
      conn
      |> send_resp(401, "")
      |> halt()
    else
      conn
    end
  end
end