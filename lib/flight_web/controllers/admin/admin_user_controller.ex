defmodule FlightWeb.Admin.UserController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Billing, Repo, Scheduling}
  alias Flight.Auth.Permission
  import Flight.Auth.Authorization

  plug(:get_user when action in [:show, :edit, :update, :add_funds, :delete])
  plug(:authorize_admin when action in [:index])
  plug(:protect_admin_users when action in [:show, :edit, :update])

  def index(conn, %{"role" => role_slug} = params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term)
    message = params["search"] && set_message(params["search"])

    render(conn, "index.html", data: data, message: message)
  end

  def show(conn, %{"tab" => "appointments"}) do
    user = conn.assigns.requested_user

    options =
      cond do
        Accounts.has_role?(user, "instructor") ->
          %{"instructor_user_id" => user.id}

        true ->
          %{"user_id" => user.id}
      end

    appointments =
      Scheduling.get_appointments(options, conn)
      |> Flight.Repo.preload([:aircraft, :instructor_user])

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
          file_name: document.file.file_name,
          file_url: Accounts.Document.file_url(document),
          id: document.id
        }
      end)

    props = %{
      admin: user_can?(current_user, [Permission.new(:documents, :modify, :all)]),
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
    render(
      conn,
      "edit.html",
      user: conn.assigns.requested_user,
      changeset: Accounts.User.create_changeset(conn.assigns.requested_user, %{}),
      skip_shool_select: true
    )
  end

  def add_funds(conn, %{"amount" => amount, "description" => description}) do
    with {:ok, cent_amount} <- Billing.parse_amount(amount),
         {:ok, {user, transaction}} <-
           Billing.add_funds_by_credit(
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
      |> redirect(to: "/admin/users/#{conn.assigns.requested_user.id}?tab=billing")
    else
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid amount. Please enter an amount in the form: 20.50")
        |> redirect(to: "/admin/users/#{conn.assigns.requested_user.id}?tab=billing")

      {:error, :negative_balance} ->
        conn
        |> put_flash(:error, "Users cannot have a negative balance.")
        |> redirect(to: "/admin/users/#{conn.assigns.requested_user.id}?tab=billing")
    end
  end

  def update(conn, %{"user" => user_form} = params) do
    role_params = Map.keys(params["role_slugs"] || %{})

    role_slugs =
      if user_can?(conn.assigns.current_user, modify_admin_permission()) do
        role_params
      else
        Enum.filter(role_params, fn p -> p != "admin" end)
      end

    case Accounts.admin_update_user_profile(
           conn.assigns.requested_user,
           user_form,
           role_slugs,
           Map.keys(params["flyer_certificate_slugs"] || %{})
         ) do
      {:ok, user} ->
        redirect(conn, to: "/admin/users/#{user.id}")

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          user: conn.assigns.requested_user,
          changeset: changeset
        )
    end
  end

  def delete(conn, params) do
    user = conn.assigns.requested_user
    Accounts.archive_user(user)

    conn =
      conn
      |> put_flash(:success, "Successfully archived #{user.first_name} #{user.last_name}")

    if params["role"] do
      redirect(conn, to: "/admin/users?role=#{params["role"]}")
    else
      redirect(conn, to: "/admin/dashboard")
    end
  end

  defp get_user(conn, _) do
    user =
      (conn.params["id"] || conn.params["user_id"])
      |> Accounts.get_school_user_by_id(conn)
      |> Repo.preload([:roles, :flyer_certificates])

    cond do
      user && !user.archived ->
        assign(conn, :requested_user, user)

      user && user.archived ->
        conn
        |> put_flash(:error, "User already removed.")
        |> redirect(to: "/admin/dashboard")
        |> halt()

      true ->
        conn
        |> put_flash(:error, "Unknown user.")
        |> redirect(to: "/admin/dashboard")
        |> halt()
    end
  end

  defp authorize_admin(conn, _) do
    if conn.query_params["role"] == "admin" do
      redirect_unless_user_can?(conn, modify_admin_permission())
    else
      conn
    end
  end

  defp protect_admin_users(conn, _) do
    requested_user_roles =
      Enum.map(
        conn.assigns.requested_user.roles,
        fn r -> r.slug end
      )

    if Enum.member?(requested_user_roles, "admin") do
      redirect_unless_user_can?(conn, modify_admin_permission())
    else
      conn
    end
  end

  defp modify_admin_permission() do
    [Permission.new(:admins, :modify, :all)]
  end

  defp set_message(search_param) do
    if String.trim(search_param) == "" do
      "Please fill out search field"
    end
  end
end
