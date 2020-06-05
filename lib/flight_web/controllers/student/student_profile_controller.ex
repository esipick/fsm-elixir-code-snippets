defmodule FlightWeb.Student.ProfileController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Billing, Repo, Scheduling}
  alias FlightWeb.StripeHelper

  require Logger

  def show(%{assigns: %{current_user: current_user}} = conn, %{"tab" => "schedule"}) do
    user = Repo.preload(current_user, [:roles, :aircrafts, :instructors, :main_instructor])

    options =
      cond do
        Accounts.has_role?(user, "instructor") ->
          %{"instructor_user_id" => user.id}

        true ->
          %{"user_id" => user.id}
      end

    appointments =
      Scheduling.get_appointments(options, conn)
      |> Repo.preload([:aircraft, :instructor_user])

    total_hrs_spent = Scheduling.calculate_appointments_duration(appointments)

    render(
      conn,
      "show.html",
      user: user,
      tab: :schedule,
      total_hrs_spent: total_hrs_spent,
      show_student_flight_hours: current_user.school.show_student_flight_hours,
      appointments: appointments,
      skip_shool_select: true
    )
  end

  def show(%{assigns: %{current_user: current_user}} = conn, %{"tab" => "billing"}) do
    user = Repo.preload(current_user, [:roles, :aircrafts, :instructors, :main_instructor])

    transactions =
      Billing.get_filtered_transactions(%{"user_id" => current_user.id}, conn)
      |> Repo.preload([:line_items, :user, :creator_user])

    total_amount_spent = Billing.calculate_amount_spent_in_transactions(transactions)

    render(
      conn,
      "show.html",
      user: user,
      tab: :billing,
      transactions: transactions,
      total_amount_spent: total_amount_spent,
      show_student_accounts_summary: current_user.school.show_student_accounts_summary,
      skip_shool_select: true
    )
  end

  def show(%{assigns: %{current_user: current_user}} = conn, params) do
    user = Repo.preload(current_user, [:roles, :aircrafts, :instructors, :main_instructor])
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
      documents: documents,
      page_number: page.page_number,
      page_size: page.page_size,
      total_entries: page.total_entries,
      total_pages: page.total_pages,
      user_id: user.id
    }

    render(conn, "show.html",
      hide_shool_select: true,
      props: props,
      tab: :documents,
      user: user
    )
  end

  def edit(conn, _) do
    user = Repo.preload(conn.assigns.current_user, [:roles, :aircrafts, :flyer_certificates])

    render(
      conn,
      "edit.html",
      user: user,
      changeset: Accounts.User.create_changeset(user, %{}),
      stripe_error: nil
    )
  end

  def update(conn, params) do
    user_form =
      with password_params when password_params != nil <- params["user"]["password"],
           true <- String.trim(password_params) == "" do
        Map.delete(params["user"], "password")
      else
        _ -> params["user"]
      end

    user = Repo.preload(conn.assigns.current_user, [:roles, :aircrafts, :flyer_certificates])

    case Accounts.regular_user_update_profile(user, user_form) do
      {:ok, _} ->
        redirect(conn, to: "/student/profile")

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          user: user,
          changeset: changeset,
          stripe_error: nil
        )
    end
  end

  def update_card(conn, params) do
    user = conn.assigns.current_user

    case Billing.update_customer_card(user, params["stripe_token"]) do
      {:ok, _} ->
        redirect(conn, to: "/student/profile")

      {:error, %Stripe.Error{} = error} ->
        render(
          conn,
          "edit.html",
          user: user,
          changeset: Accounts.user_changeset(%Accounts.User{}, %{}, user),
          stripe_error: StripeHelper.error_message(error)
        )
    end
  end
end
