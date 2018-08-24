defmodule FlightWeb.Admin.UserController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Billing, Scheduling}

  plug(:get_user when action in [:show, :edit, :update, :add_funds])

  def index(conn, %{"role" => role_slug}) do
    render(conn, "index.html", data: FlightWeb.Admin.UserListData.build(role_slug, conn))
  end

  def show(conn, %{"tab" => "schedule"}) do
    appointments =
      Scheduling.get_appointments(%{"user_id" => conn.assigns.requested_user.id}, conn)
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
    case Accounts.admin_update_user_profile(
           conn.assigns.requested_user,
           user_form,
           Map.keys(params["role_slugs"] || %{}),
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

  defp get_user(conn, _) do
    user =
      (conn.params["id"] || conn.params["user_id"])
      |> Accounts.get_user(conn)
      |> Flight.Repo.preload([:roles, :flyer_certificates])

    conn
    |> assign(:requested_user, user)
  end
end
