defmodule FlightWeb.API.BulkInvoiceController do
  use FlightWeb, :controller

  import Flight.Auth.Authorization

  alias FlightWeb.{ViewHelpers, StripeHelper}

  alias Flight.Billing.{
    CreateBulkInvoice,
    PaymentError
  }

  plug(:authorize_create when action in [:create])

  def create(conn, %{"bulk_invoice" => invoice_params}) do
    case CreateBulkInvoice.run(invoice_params, conn) do
      {:ok, bulk_invoice} ->
        conn
        |> put_status(201)
        |> render("show.json", bulk_invoice: bulk_invoice)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{
          error: %{message: "Could not save invoice. Please correct errors in the form."},
          errors: ViewHelpers.translate_errors(changeset)
        })

      {:error, %Stripe.Error{} = error} ->
        conn
        |> put_status(error.extra.http_status)
        |> json(%{stripe_error: StripeHelper.human_error(error.message)})

      {:error, %PaymentError{} = error} ->
        conn
        |> put_status(400)
        |> json(%{stripe_error: StripeHelper.human_error(error.message)})

      {:error, msg} ->
        conn
        |> put_status(422)
        |> json(%{
          error: %{message: msg}
        })
    end
  end

  def send_bulk_invoice(conn, %{"bulk_invoice" => %{"invoice_ids" => invoice_ids, "user_id" => user_id}}) when is_list(invoice_ids) do
      Flight.Billing.Services.Utils.send_bulk_invoice_email(user_id, invoice_ids, conn)
      
      conn
      |> put_status(201)
      |> json(%{data: "success"})
  end

  defp authorize_create(conn, _) do
    user = conn.assigns.current_user

    if staff_member?(user) do
      conn
    else
      halt_unauthorized_response(conn)
    end
  end
end
