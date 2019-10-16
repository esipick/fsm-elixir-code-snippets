defmodule FlightWeb.API.InvoiceController do
  use FlightWeb, :controller

  alias Flight.Repo
  alias FlightWeb.ViewHelpers
  alias Flight.Auth.Permission
  alias Flight.Billing.{Invoice, CreateInvoice, UpdateInvoice}

  plug(:get_invoice when action in [:update])

  def create(conn, %{"invoice" => invoice_params}) do
    case CreateInvoice.run(invoice_params, conn) do
      {:ok, invoice} ->
        invoice = Repo.preload(invoice, [:line_items, :user])

        conn
        |> put_status(201)
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

  def update(conn, %{"invoice" => invoice_params}) do
    case UpdateInvoice.run(conn.assigns.invoice, invoice_params, conn) do
      {:ok, invoice} ->
        invoice = Repo.preload(invoice, [:line_items, :user])

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
