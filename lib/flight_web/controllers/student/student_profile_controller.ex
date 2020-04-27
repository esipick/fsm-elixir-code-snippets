defmodule FlightWeb.Student.ProfileController do
  use FlightWeb, :controller

  alias Flight.Accounts

  def show(%{assigns: %{current_user: current_user}} = conn, params) do
    user = Flight.Repo.preload(current_user, [:roles, :aircrafts, :instructors, :main_instructor])
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
    user =
      Flight.Repo.preload(conn.assigns.current_user, [:roles, :aircrafts, :flyer_certificates])

    render(
      conn,
      "edit.html",
      user: user,
      changeset: Accounts.User.create_changeset(user, %{})
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

    user =
      Flight.Repo.preload(conn.assigns.current_user, [:roles, :aircrafts, :flyer_certificates])

    case Accounts.regular_user_update_profile(user, user_form) do
      {:ok, _} ->
        redirect(conn, to: "/student/profile")

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          user: user,
          changeset: changeset
        )
    end
  end
end
