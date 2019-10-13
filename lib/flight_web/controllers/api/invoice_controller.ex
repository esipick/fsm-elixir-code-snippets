defmodule FlightWeb.API.InvoiceController do
  use FlightWeb, :controller

  alias Flight.{Repo, Billing.CreateInvoice}
  alias FlightWeb.ViewHelpers

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
end
