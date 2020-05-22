defmodule FlightWeb.API.InvoiceController do
  use FlightWeb, :controller

  import Ecto.Query

  alias Flight.Repo
  alias Flight.Auth.Permission
  import Flight.Auth.Authorization
  alias FlightWeb.{ViewHelpers, Pagination, StripeHelper}

  alias Flight.Billing.{
    Invoice,
    CreateInvoice,
    UpdateInvoice,
    CreateInvoiceFromAppointment,
    CalculateInvoice,
    PaymentError
  }

  plug(:get_invoice when action in [:update, :show, :delete])
  plug(:authorize_view when action in [:show])
  plug(:authorize_modify when action in [:create, :index, :delete])
  plug(:authorize_update when action in [:update])
  plug(:check_paid_invoice when action in [:update, :delete])
  plug(:check_archived_invoice when action in [:update, :delete])

  def index(conn, params) do
    page_params = Pagination.params(params)
    page = from(i in Invoice, where: i.archived == false) |> Repo.paginate(page_params)
    invoices = Repo.preload(page.entries, [:user, :line_items, :appointment])

    conn
    |> put_status(200)
    |> Scrivener.Headers.paginate(page)
    |> render("index.json", invoices: invoices)
  end

  def appointments(conn, params) do
    appointments =
      Flight.Queries.Appointment.billable(conn, params)
      |> FlightWeb.API.AppointmentView.preload()

    render(conn, "appointments.json", appointments: appointments)
  end

  def calculate(conn, %{"invoice" => invoice_params}) do
    case CalculateInvoice.run(invoice_params, conn) do
      {:ok, calculated_params} ->
        conn
        |> put_status(200)
        |> json(calculated_params)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})
    end
  end

  def create(conn, %{"invoice" => invoice_params}) do
    case CreateInvoice.run(invoice_params, conn) do
      {:ok, invoice} ->
        invoice = Repo.preload(invoice, [:line_items, :user, :school, :appointment], force: true)

        conn
        |> put_status(201)
        |> render("show.json", invoice: invoice)

      {:error, %Ecto.Changeset{errors: [invoice: {message, []}]} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{error: %{message: message}, errors: ViewHelpers.translate_errors(changeset)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{
          error: %{message: "Could not save invoice. Please correct errors in the form."},
          errors: ViewHelpers.translate_errors(changeset)
        })

      {:error, id, %Ecto.Changeset{errors: [invoice: {message, []}]} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{
          id: id,
          error: %{message: message},
          errors: ViewHelpers.translate_errors(changeset)
        })

      {:error, id, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{
          id: id,
          error: %{message: "Could not save invoice. Please correct errors in the form."},
          errors: ViewHelpers.translate_errors(changeset)
        })

      {:error, id, %Stripe.Error{} = error} ->
        conn
        |> put_status(error.extra.http_status)
        |> json(%{id: id, stripe_error: StripeHelper.human_error(error.message)})

      {:error, id, %PaymentError{} = error} ->
        conn
        |> put_status(400)
        |> json(%{id: id, stripe_error: StripeHelper.human_error(error.message)})
    end
  end

  def update(conn, %{"invoice" => invoice_params}) do
    case UpdateInvoice.run(conn.assigns.invoice, invoice_params, conn) do
      {:ok, invoice} ->
        invoice =
          Repo.get(Invoice, invoice.id)
          |> Repo.preload([:line_items, :user, :school, :appointment], force: true)

        conn
        |> put_status(200)
        |> render("show.json", invoice: invoice)

      {:error, %Ecto.Changeset{errors: [invoice: {message, []}]} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{error: %{message: message}, errors: ViewHelpers.translate_errors(changeset)})

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
    end
  end

  def show(conn, _params) do
    invoice =
      Repo.preload(conn.assigns.invoice, [:line_items, :user, :school, :appointment], force: true)

    conn
    |> put_status(200)
    |> render("show.json", invoice: invoice)
  end

  def delete(conn, _params) do
    Invoice.archive(conn.assigns.invoice)

    resp(conn, 204, "")
  end

  def get_from_appointment(conn, %{"appointment_id" => appointment_id} = _params) do
    case CreateInvoiceFromAppointment.fetch_invoice(appointment_id) do
      {:ok, invoice} ->
        invoice = Repo.preload(invoice, [:line_items, :user, :school, :appointment])

        conn
        |> put_status(200)
        |> render("show.json", invoice: invoice)

      {:error, _} ->
        conn
        |> put_status(200)
        |> json(%{data: nil})
    end
  end

  def from_appointment(conn, %{"appointment_id" => appointment_id} = params) do
    case CreateInvoiceFromAppointment.run(appointment_id, params, conn) do
      {:ok, invoice} ->
        invoice =
          Repo.get(Invoice, invoice.id)
          |> Repo.preload([:line_items, :user, :school, :appointment], force: true)

        conn
        |> put_status(201)
        |> render("show.json", invoice: invoice)

      {:error, %Ecto.Changeset{errors: [invoice: {message, []}]} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{error: %{message: message}, errors: ViewHelpers.translate_errors(changeset)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})

      {:error, _invoice_id, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})
    end
  end

  def payment_options(conn, _) do
    render(conn, "payment_options.json")
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
    if staff_member?(conn) do
      conn
    else
      halt_unauthorized_response(conn)
    end
  end

  defp staff_member?(conn) do
    user_can?(conn.assigns.current_user, [Permission.new(:invoice, :modify, :all)])
  end

  defp authorize_view(conn, _) do
    user = conn.assigns.current_user

    if user_can?(user, [Permission.new(:invoice, :view, :all)]) ||
         user_can?(user, [Permission.new(:invoice, :view, {:personal, conn.assigns.invoice})]) do
      conn
    else
      halt_unauthorized_response(conn)
    end
  end

  defp authorize_update(conn, _) do
    user = conn.assigns.current_user

    if staff_member?(conn) ||
         user_can?(user, [Permission.new(:invoice, :modify, {:personal, conn.assigns.invoice})]) do
      conn
    else
      halt_unauthorized_response(conn)
    end
  end

  defp check_paid_invoice(conn, _) do
    if conn.assigns.invoice.status == :paid do
      halt_unauthorized_response(conn, "Invoice has already been paid.")
    else
      conn
    end
  end

  defp check_archived_invoice(conn, _) do
    if conn.assigns.invoice.archived == true do
      halt_not_found_response(conn, "Invoice has already been removed.")
    else
      conn
    end
  end
end
