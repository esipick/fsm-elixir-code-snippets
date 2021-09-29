defmodule FlightWeb.Billing.InvoiceController do
  use FlightWeb, :controller

  import Flight.Auth.Authorization

  alias Flight.{Auth.InvoicePolicy, Repo}
  alias Flight.Billing.{Invoice, InvoiceCustomLineItem}
  alias FlightWeb.{Pagination, Billing.InvoiceStruct}

  plug(:get_invoice when action in [:edit, :show, :delete])
  plug(:authorize_delete when action in [:delete])
  plug(:authorize_modify when action in [:new, :edit])
  plug(:authorize_view when action in [:show])
  plug(:check_paid_invoice when action in [:update, :edit, :delete])
  plug(:check_archived_invoice when action in [:show, :edit, :update, :delete])

  def index(conn, params) do
    page_params = Pagination.params(params)
    user = conn.assigns.current_user

    result =
      if staff_member?(user) do
        Flight.Queries.Invoice.all(conn, params)
      else
        Flight.Queries.Invoice.own_invoices(conn, params)
      end

    page = result |> Repo.paginate(page_params)
    invoices = page |> Enum.map(fn invoice -> InvoiceStruct.build(invoice) end)

    render(conn, "index.html", page: page, invoices: invoices, params: params)
  end

  def new(conn, params) do
    appointment =
      if params["appointment_id"] do
        Repo.get(Flight.Scheduling.Appointment, params["appointment_id"])
        |> Repo.preload([:aircraft, :instructor_user])
        |> FlightWeb.API.AppointmentView.preload()
      end

    props =
      base_invoice_props(conn)
      |> Map.merge(%{action: "create", appointment: appointment})

    props =
      if "student" in props.user_roles or "renter" in props.user_roles do
        Map.put(props, :payment_method, :balance)
      else
        props
      end

    course_id = params["course_id"]

    course = if !is_nil(course_id) do
        case Integer.parse(course_id) do
          :error ->
            IO.puts "Invalid course id"
            %{}
          {id, _rem} ->
            %{assigns: %{current_user: current_user}} = conn
            
            data_url = Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/category_mgt.php"
            
            body = Poison.encode!(%{
              "action": "get_course",
              "id": id,
              "webtoken": Flight.Utils.get_webtoken(current_user.school_id)
            })

            case HTTPoison.post(data_url,body) do
              {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                case Poison.decode(body) do
                  {:ok, response} ->
                    # we're getting a list of length 1 for "courses" key
                    [course | _] = Map.get(response, "course")
                    # return course info
                    course
                  {:error, error} -> error
                end
              {:ok, %HTTPoison.Response{status_code: 404}} ->
                %{}
              {:error, %HTTPoison.Error{reason: reason}} ->
                %{}
            end
        end
    end

    props = Map.put(props, :course, course)
    
    render(conn, "new.html", props: props)
  end

  def edit(conn, _) do
    props =
      base_invoice_props(conn)
      |> Map.put(:action, "edit")
      |> Map.put(:id, conn.assigns.invoice.id)

    render(conn, "edit.html", props: props, skip_shool_select: true)
  end

  def show(conn, _) do
    invoice = InvoiceStruct.build(conn.assigns.invoice)

    render(conn, "show.html",
      invoice: invoice,
      user: conn.assigns.current_user,
      skip_shool_select: true
    )
  end

  def send_invoice(conn, %{"id" => id}) when not is_nil(id) do
    invoice = Repo.get(Invoice, id)
    Flight.InvoiceEmail.send_paid_invoice_email(invoice, conn)
    
    conn
    |> put_flash(:success, "Invoice sent successfully")
    |> redirect(to: "/billing/invoices")
  end

  def delete(conn, params) do
    Invoice.archive(conn.assigns.invoice)
    search = Map.get(params, "search", nil)
    status = Map.get(params, "status", nil)
    start_date = Map.get(params, "start_date", nil)
    end_date = Map.get(params, "end_date", nil)

    conn
    |> put_flash(:success, "Invoice was successfully deleted.")
    |> redirect(to:  "/billing/invoices?search=#{search}&start_date=#{start_date}&end_date=#{end_date}&status=#{status}")
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

      staff_member?(conn.assigns.current_user) ->
        conn
        |> put_flash(:error, "Can't modify invoice that is already paid.")
        |> redirect(to: "/billing/invoices/#{conn.assigns.invoice.id}")
        |> halt()

      invoice.user_id == user.id ->
        conn
        |> put_flash(:error, "Can't modify invoice that is already paid.")
        |> redirect(to: "/billing/invoices/#{invoice.id}")
        |> halt()

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
      redirect_unathorized_user(conn)
    end
  end

  defp authorize_delete(conn, _) do
    invoice = conn.assigns.invoice
    user = conn.assigns.current_user

    if InvoicePolicy.delete?(user, invoice) do
      conn
    else
      redirect_unathorized_user(conn)
    end
  end

  def checkout_success(conn, %{"session_id" => session_id}) do
    Invoice.get_by_session_id(session_id)
    |> case do
      nil -> 
        conn
        |> put_flash(:error, "Invalid Session id.")
        |> redirect(to: "/billing/invoices")

      %{id: id} ->

        render(conn, "success.html", props: %{invoice_id: id})
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
    |> put_flash(:error, "Invoice has been removed.")
    |> redirect(to: "/billing/invoices")
  end

  defp check_archived_invoice(conn, _) do
    conn
  end

  defp base_invoice_props(conn) do
    current_user = 
      conn.assigns.current_user
      |> Repo.preload(:roles)

    roles = Enum.map(current_user.roles, &(&1.slug))
    
    %{
      user_roles: roles,
      current_user_id: current_user.id,
      custom_line_items: custom_line_items_props(conn),
      creator: FlightWeb.API.UserView.render("skinny_user.json", user: current_user),
      tax_rate: current_user.school.sales_tax || 0,
      staff_member: staff_member?(current_user)
    }
  end

  defp custom_line_items_props(conn) do
    InvoiceCustomLineItem.get_custom_line_items(conn)
    |> Enum.map(fn custom_line_item ->
      %{
        default_rate: custom_line_item.default_rate,
        description: custom_line_item.description,
        taxable: custom_line_item.taxable,
        deductible: custom_line_item.deductible
      }
    end)
  end
end
