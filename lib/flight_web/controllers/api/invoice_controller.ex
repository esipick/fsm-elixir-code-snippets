defmodule FlightWeb.API.InvoiceController do
  use FlightWeb, :controller

  alias Flight.{Repo, Billing.Invoice}

  def create(conn, %{"invoice" => invoice_params}) do
    case Invoice.create(invoice_params) do
      {:ok, invoice} ->
        invoice = Repo.preload(invoice, [:line_items, :user])

        conn
        |> put_status(201)
        |> render("show.json", invoice: invoice)
      {:error, changeset} ->
        conn
        |> put_status(422)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end
end
