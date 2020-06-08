defmodule FlightWeb.Admin.UserController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Billing, Repo, Scheduling, Queries}
  alias Flight.Auth.Permission
  alias FlightWeb.StripeHelper
  alias FlightWeb.Admin.InvitationController

  import Flight.Auth.Authorization

  plug(:get_user when action in [:show, :edit, :update, :update_card, :add_funds, :delete])
  plug(:check_user when action in [:restore])
  plug(:authorize_admin when action in [:index])
  plug(:protect_admin_users when action in [:show, :edit, :update])

  def index(conn, %{"role" => "user" = role, "tab" => "archived"} = params) do
    role_slug= %{slug: role}
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)

    data =
      FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term, :archived)

    message = params["search"] && set_message(params["search"])

    render(conn, "users.html", data: data, message: message, tab: :archived)
  end

  def index(conn, %{"role" => role_slug, "tab" => "archived"} = params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)

    data =
      FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term, :archived)

    message = params["search"] && set_message(params["search"])

    render(conn, "index.html", data: data, message: message, tab: :archived)
  end

  def index(conn, %{"role" => "user" =role} = params) do
    role_slug= %{slug: role}
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term, nil)
    message = params["search"] && set_message(params["search"])
    available_user_roles = Accounts.get_user_roles(conn)

    render(
      conn,
      "users.html",
      data: data,
      message: message,
      tab: :main,
      changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
      request_path: InvitationController.invite_request_path(conn),
      available_user_roles: available_user_roles
    )
  end

  def index(conn, %{"role" => role_slug} = params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term, nil)
    message = params["search"] && set_message(params["search"])

    render(
      conn,
      "index.html",
      data: data,
      message: message,
      tab: :main,
      changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
      request_path: InvitationController.invite_request_path(conn),
      role: Accounts.role_for_slug(role_slug)
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
          file: %{name: document.file.file_name, url: Accounts.Document.file_url(document)},
          id: document.id,
          title: document.title || document.file.file_name
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
      stripe_error: nil
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

    role_params = params["role_slugs"]

    role_slugs =
      with %{} <- role_params, params <- Map.keys(params["role_slugs"]) do
        if user_can?(conn.assigns.current_user, modify_admin_permission()) do
          params
        else
          Enum.filter(params, fn p -> p != "admin" end)
        end
      else
        "" ->
          %{}

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
           role_slugs,
           aircrafts,
           certs,
           instructors
         ) do
      {:ok, user} ->
        redirect(conn, to: "/admin/users/#{user.id}")

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

    case Flight.Billing.update_customer_card(user, params["stripe_token"]) do
      {:ok, _} ->
        redirect(conn, to: "/admin/users/#{user.id}")

      {:error, %Stripe.Error{} = error} ->
        user = conn.assigns.requested_user
        aircrafts = Accounts.get_aircrafts(conn)
        role = Accounts.role_for_slug("instructor")
        instructors = Queries.User.get_users_by_role(role, conn)

        render(
          conn,
          "edit.html",
          aircrafts: aircrafts,
          changeset: Accounts.user_changeset(%Accounts.User{}, %{}, user),
          instructors: instructors,
          skip_shool_select: true,
          user: user,
          stripe_error: StripeHelper.error_message(error)
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
      redirect(conn, to: "/admin/users?role=#{params["role"]}&page=#{params["page"]}")
    else
      redirect(conn, to: "/admin/dashboard")
    end
  end

  def restore(conn, params) do
    user = conn.assigns.requested_user
    Accounts.restore_user(user)

    conn =
      conn
      |> put_flash(:success, "Successfully restored #{user.first_name} #{user.last_name} account")

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
      |> Repo.preload([:roles, :aircrafts, :flyer_certificates, :instructors, :main_instructor])

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

  defp check_user(conn, _) do
    user =
      conn.params["user_id"]
      |> Accounts.get_school_user_by_id(conn)

    cond do
      user && user.archived ->
        assign(conn, :requested_user, user)

      user && !user.archived ->
        conn
        |> put_flash(:error, "#{user.first_name} #{user.last_name} account is already restored")
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
