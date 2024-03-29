defmodule FlightWeb.Instructor.StudentController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Billing, Repo, Scheduling, Queries}
  alias FlightWeb.StripeHelper

  plug(:get_user when action in [:show, :edit, :update, :add_funds, :update_card])
  plug(:allow_only_students when action in [:show, :edit, :update])

  def index(conn, params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    only_assgined_students = conn.req_cookies["only_assgined_students"] == "true"

    page_params =
      if only_assgined_students,
        do: Map.put(page_params, :instructor_id, conn.assigns.current_user.id),
        else: page_params

    data = FlightWeb.Admin.UserListData.build(conn, "student", page_params, search_term, "", "", nil)
    message = params["search"] && set_message(params["search"])

    render(conn, "index.html",
      data: data,
      only_assgined_students: only_assgined_students,
      message: message
    )
  end

  def show(conn, %{"tab" => "appointments"}) do
    user = Repo.preload(conn.assigns.requested_user, :school)

    options =
      cond do
        Accounts.has_role?(user, "instructor") ->
          %{"instructor_user_id" => user.id}

        true ->
          %{"user_id" => user.id}
      end

    appointments =
      Scheduling.get_appointments(options, conn)
      |> Flight.Repo.preload([:aircraft, :instructor_user, :simulator, :room])

    render(
      conn,
      "show.html",
      user: user,
      tab: :appointments,
      appointments: appointments,
      skip_shool_select: true
    )
  end

  def show(conn, %{"tab" => "billing"}) do
    transactions =
      Billing.get_filtered_transactions(%{"user_id" => conn.assigns.requested_user.id}, conn)
      |> Flight.Repo.preload([:line_items, :user, :creator_user])

    render(
      conn,
      "show.html",
      user: conn.assigns.requested_user,
      tab: :billing,
      transactions: transactions,
      skip_shool_select: true
    )
  end

  def show(%{assigns: %{current_user: current_user, requested_user: user}} = conn, params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    page = Accounts.Document.documents_by_page(user.id, page_params, search_term)
    today = DateTime.to_date(Timex.now(current_user.school.timezone))

    documents =
      page.entries
      |> Enum.map(fn document ->
        %{
          expired: Date.compare(document.expires_at || Date.add(today, 2), today),
          expires_at: document.expires_at,
          file: %{name: document.file.file_name, url: Accounts.Document.file_url(document)},
          id: document.id,
          title: document.title || document.file.file_name
        }
      end)

    props = %{
      documents: documents,
      page_number: page.page_number,
      page_size: page.page_size,
      total_entries: page.total_entries,
      total_pages: page.total_pages,
      user_id: user.id
    }

    render(conn, "show.html",
      props: props,
      skip_shool_select: true,
      tab: :documents,
      user: user
    )
  end

  def edit(conn, _params) do
    user = conn.assigns.requested_user
    aircrafts = Accounts.get_aircrafts_only(conn)
    role = Accounts.role_for_slug("instructor")
    instructors = Queries.User.get_users_by_role(role, conn)

    render(
      conn,
      "edit.html",
      aircrafts: aircrafts,
      changeset: Accounts.User.create_changeset(user, %{}),
      instructors: instructors,
      skip_shool_select: true,
      user: user,
      stripe_error: nil
    )
  end

  def add_funds(conn, %{"amount" => amount, "description" => description}) do
    with {:ok, cent_amount} <- Billing.parse_amount(amount),
         {:ok, {user, transaction}} <-
           Fsm.Billing.add_funds_by_credit(
             conn.assigns.requested_user,
             conn.assigns.current_user,
             cent_amount,
             description
           ) do
      message =
        if transaction.type == "credit" do
          "Successfully added #{FlightWeb.ViewHelpers.currency(transaction.total)} to #{
            user.first_name
          }'s balance."
        else
          "Successfully removed #{FlightWeb.ViewHelpers.currency(transaction.total)} from #{
            user.first_name
          }'s balance."
        end

      Flight.Billing.approve_transactions_within_balance(user)

      conn
      |> put_flash(:success, message)
      |> redirect(to: "/instructor/students/#{conn.assigns.requested_user.id}?tab=billing")
    else
      {:error, :invalid_amount} ->
        conn
        |> put_flash(:error, "Invalid amount. Please enter an amount in the form: 20.50")
        |> redirect(to: "/instructor/students/#{conn.assigns.requested_user.id}?tab=billing")

      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Amount or description is empty")
        |> redirect(to: "/instructor/students/#{conn.assigns.requested_user.id}?tab=billing")

      {:error, :negative_balance} ->
        conn
        |> put_flash(:error, "Students cannot have a negative balance.")
        |> redirect(to: "/instructor/students/#{conn.assigns.requested_user.id}?tab=billing")
    end
  end

  def update(conn, %{"user" => user_form} = params) do
    aircrafts =
      case Map.get(params["user"], "aircrafts") do
        params when params == [""] ->
          []

        params when is_list(params) ->
          params
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.to_integer(&1))

        _ ->
          nil
      end

    instructors =
      case Map.get(params["user"], "instructors") do
        params when params == [""] ->
          []

        params when is_list(params) ->
          params
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.to_integer(&1))

        _ ->
          nil
      end

    certs =
      case params["flyer_certificate_slugs"] do
        %{} = params -> Map.keys(params)
        _ -> nil
      end

     case Accounts.admin_update_user_profile(
           conn.assigns.requested_user,
           user_form,
           nil,
           aircrafts,
           certs,
           instructors
         ) do
      {:ok, user} ->
        redirect(conn, to: "/instructor/students/#{user.id}")

      {:error, changeset} ->
        user = conn.assigns.requested_user
        aircrafts = Accounts.get_aircrafts(conn)
        role = Accounts.role_for_slug("instructor")
        instructors = Queries.User.get_users_by_role(role, conn)

        render(
          conn,
          "edit.html",
          aircrafts: aircrafts,
          changeset: changeset,
          instructors: instructors,
          skip_shool_select: true,
          user: user,
          stripe_error: nil
        )
    end
  end

  def update_card(conn, params) do
    user = conn.assigns.requested_user

    case Billing.update_customer_card(user, params["stripe_token"]) do
      {:ok, _} ->
        redirect(conn, to: "/instructor/students/#{user.id}")

      {:error, %Stripe.Error{} = error} ->
        user = conn.assigns.requested_user
        aircrafts = Accounts.get_aircrafts(conn)
        role = Accounts.role_for_slug("instructor")
        instructors = Queries.User.get_users_by_role(role, conn)

        render(
          conn,
          "edit.html",
          aircrafts: aircrafts,
          changeset: Accounts.User.create_changeset(user, %{}),
          instructors: instructors,
          skip_shool_select: true,
          user: user,
          stripe_error: StripeHelper.error_message(error)
        )
     end
  end

  defp get_user(conn, _) do
    user =
      (conn.params["id"] || conn.params["student_id"])
      |> Accounts.get_school_user_by_id(conn)
      |> Repo.preload([:roles, :aircrafts, :flyer_certificates, :instructors, :main_instructor])

    if user && !user.archived do
      assign(conn, :requested_user, user)
    else
      conn
      |> put_flash(:error, "Unknown student.")
      |> redirect(to: "/instructor/profile")
      |> halt()
    end
  end

  defp allow_only_students(conn, _) do
    requested_user_roles = Enum.map(conn.assigns.requested_user.roles, fn r -> r.slug end)

    if Enum.member?(requested_user_roles, "student") do
      conn
    else
      redirect_unathorized_user(conn)
    end
  end

  defp set_message(search_param) do
    if String.trim(search_param) == "" do
      "Please fill out search field"
    end
  end
end
