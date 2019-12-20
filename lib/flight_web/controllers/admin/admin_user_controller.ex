defmodule FlightWeb.Admin.UserController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Billing, Scheduling}
  alias Flight.Auth.Permission
  import Flight.Auth.Authorization

  plug(:get_user when action in [:show, :edit, :update, :add_funds])
  plug(:authorize_admin when action in [:index])
  plug(:protect_admin_users when action in [:show, :edit, :update])

  def index(conn, %{"role" => role_slug} = params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term)

    render(conn, "index.html", data: data)
  end

  def show(conn, %{"tab" => "schedule"}) do
    appointments =
      Scheduling.get_appointments(
        %{"user_id" => conn.assigns.requested_user.id, "walltime" => "true"},
        conn
      )
      |> Flight.Repo.preload([:aircraft, :instructor_user])

    render(
      conn,
      "show.html",
      user: conn.assigns.requested_user,
      tab: :schedule,
      appointments: appointments
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
      transactions: transactions
    )
  end

  def show(conn, _params) do
    render(conn, "show.html", user: conn.assigns.requested_user, tab: :profile)
  end

  def edit(conn, _params) do
    render(
      conn,
      "edit.html",
      user: conn.assigns.requested_user,
      changeset: Accounts.User.create_changeset(conn.assigns.requested_user, %{})
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

  def delete(conn, %{"id" => id} = params) do
    user = Flight.Accounts.get_user(id, conn)

    Flight.Accounts.archive_user(user)

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
      |> Accounts.get_user(conn)
      |> Flight.Repo.preload([:roles, :flyer_certificates])

    conn
    |> assign(:requested_user, user)
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
end
