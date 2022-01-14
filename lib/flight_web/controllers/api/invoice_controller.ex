defmodule FlightWeb.API.InvoiceController do
  use FlightWeb, :controller

  import Flight.Auth.Authorization
  require Logger
  alias Flight.Auth.Permission
  alias Flight.Repo
  alias FlightWeb.{ViewHelpers, Pagination, StripeHelper}
  alias Flight.Billing.{
    CalculateInvoice,
    CreateInvoice,
    CreateInvoiceFromAppointment,
    Invoice,
    PaymentError,
    UpdateInvoice
  }
  plug(:check_course_is_paid when action in [:create])
  plug(:get_invoice when action in [:update, :show, :delete])
  plug(:authorize_view when action in [:show])
  plug(:authorize_create when action in [:create])
  plug(:authorize_staff_member when action in [:index, :delete])
  plug(:authorize_update when action in [:update])
  plug(:check_paid_invoice when action in [:update, :delete])
  plug(:check_archived_invoice when action in [:update, :delete])
  plug(:check_invisible_invoice when action in [:delete])

  def index(conn, params) do
    page_params = Pagination.params(params)
    user = conn.assigns.current_user

    result =
      if staff_member?(user) do
        Flight.Queries.Invoice.all(conn, params)
      else
        Flight.Queries.Invoice.own_invoices(conn, params)
      end

    {page, invoices} =
      if params["skip_pagination"] do
        {nil, Repo.all(result)}
      else
        page = Repo.paginate(result, page_params)
        {page, page.entries}
      end

    invoices = Repo.preload(invoices, [:user, :line_items, :appointment])

    conn
    |> put_status(200)
    |> Pagination.apply_headers(page)
    |> render("index.json", invoices: invoices)
  end

  def appointments(conn, params) do
    appointments =
      Flight.Queries.Appointment.billable(conn, params)
      |> FlightWeb.API.AppointmentView.preload()

    render(conn, "appointments.json", appointments: appointments)
  end

  def calculate(conn, %{"invoice" => invoice_params}) do

    with {:ok, calculated_params} <- CalculateInvoice.run(invoice_params, conn) do
        conn
        |> put_status(200)
        |> json(calculated_params)
        
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})

      {:error, error} -> 
        conn
        |> put_status(422)
        |> json(%{errors: [error]})
    end
  end

  def create(conn, %{"invoice" => invoice_params}) do
    # validating changeset here because iOS calls invoice_from_appointment API with empty body
    # which calls createInvoice.run to create an invoice with default payment_option balance
    # while we want to check payment_option in this API.

    %Invoice{}
    |> Invoice.payment_options_changeset(invoice_params)
    |> case do
      %Ecto.Changeset{valid?: true} ->
        CreateInvoice.run(invoice_params, conn)
      
      changeset -> {:error, changeset}
    end
    |> render_created_invoice(conn)
  end

  def update(conn, %{"invoice" => invoice_params}) do
    invoice_params = Map.put(invoice_params, "is_visible", true)

    case UpdateInvoice.run(conn.assigns.invoice, invoice_params, conn) do
      {:ok, invoice} ->
        session_info = Map.take(invoice, [:session_id, :connect_account, :pub_key])
        
        invoice =
          Repo.get(Invoice, invoice.id)
          |> Repo.preload([:line_items, :user, :school, :appointment], force: true)
          |> Map.merge(session_info)

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
        status = Map.get(error.extra, :http_status) || 422
        conn
        |> put_status(status)
        |> json(%{stripe_error: StripeHelper.human_error(error)})

      {:error, %PaymentError{} = error} ->
        conn
        |> put_status(400)
        |> json(%{stripe_error: StripeHelper.human_error(error.message)})

      {:error, msg} ->
        conn
        |> put_status(422)
        |> json(%{error: %{message: msg}})
    end
  end

  def get_invoice_pdf(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"id" => id}) do
      with {:ok, url} <- Flight.Bills.get_invoice_url(id, school_id) do
        json(conn, %{"url" => url})

      else
        {:error, error} ->
          conn
        |> put_status(422)
        |> json(%{error: %{message: error}})
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
    CreateInvoiceFromAppointment.run(appointment_id, params, conn)
    |> render_created_invoice(conn)
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

  defp check_course_is_paid(conn, _) do
    #check if course is already paid.

    if conn.params["invoice"]["course_id"]  do
      courseInvoice =  Fsm.Billing.Invoices.getCourseInvoice(conn.params["invoice"]["course_id"], conn.params["invoice"]["user_id"])
      #Logger.info fn -> "courseInvoice111111111111111111111------------------------------------------: #{inspect courseInvoice}" end
      if courseInvoice == nil do
        conn
      else
        halt_not_found_response(conn, "Invoice has already paid.")
      end
    else
      conn
    end
  end

  defp authorize_create(conn, _) do
    user = conn.assigns.current_user
    own_invoice = conn.params["invoice"]["user_id"] == user.id

    if staff_member?(user) || own_invoice do
      conn
    else
      halt_unauthorized_response(conn)
    end
  end

  defp authorize_staff_member(conn, _) do
    if staff_member?(conn.assigns.current_user) do
      conn
    else
      halt_unauthorized_response(conn)
    end
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

    if staff_member?(conn.assigns.current_user) ||
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

  defp check_invisible_invoice(conn, _) do
    if conn.assigns.invoice.is_visible == false do
      halt_not_found_response(conn, "Invoice can not be deleted as it is not created yet.")
    else
      conn
    end
  end

  defp render_created_invoice(result, conn) do
    case result do
      {:ok, invoice} ->
        session_info = Map.take(invoice, [:session_id, :connect_account, :pub_key])
        invoice = 
          invoice
          |> Repo.preload([:line_items, :user, :school, :appointment], force: true)
          |> Map.merge(session_info)

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
        |> json(%{id: id, stripe_error: StripeHelper.human_error(error)})

      {:error, id, %PaymentError{} = error} ->
        conn
        |> put_status(400)
        |> json(%{id: id, stripe_error: StripeHelper.human_error(error.message)})

      {:error, msg} ->
        conn
        |> put_status(422)
        |> json(%{error: %{message: msg}})

      {:error, id, msg} ->
          conn
          |> put_status(400)
          |> json(%{
            id: id,
            error: %{message: msg}
          })
    end
  end
end
