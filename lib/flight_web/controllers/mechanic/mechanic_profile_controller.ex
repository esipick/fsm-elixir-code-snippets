defmodule FlightWeb.Mechanic.ProfileController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Billing, Repo, Scheduling}
  alias FlightWeb.StripeHelper

  require Logger

  def show(%{assigns: %{current_user: current_user}} = conn, params) do
    user = Repo.preload(current_user, [:roles, :aircrafts])
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
      hide_shool_select: true,
      props: props,
      tab: :documents,
      user: user
    )
  end

  def edit(conn, _) do
    user = Repo.preload(conn.assigns.current_user, [:roles, :aircrafts])

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
        conn
        |> put_flash(:success, "Profile updated successfully")
        |> redirect(to: "/mechanic/profile")

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
end
