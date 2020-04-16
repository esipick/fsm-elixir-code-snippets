defmodule FlightWeb.API.DocumentController do
  use FlightWeb, :controller

  alias FlightWeb.ViewHelpers
  alias Flight.Accounts
  alias Accounts.Document

  plug(:authorize_student when action in [:index])
  plug(:authorize_admin when action in [:create, :delete])

  def create(%{assigns: %{current_user: user}} = conn, %{
        "document" => document_params,
        "user_id" => user_id
      }) do
    user = Flight.Repo.preload(user, :school)
    params = Map.put(document_params, "user_id", user_id)

    case Document.create_document(params) do
      {:ok, %{document_with_file: document}} ->
        render(conn, "show.json", document: document, timezone: user.school.timezone)

      {:error, _, changeset, _} ->
        conn
        |> put_status(422)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id, "user_id" => user_id}) do
    result = Document.delete_document(id, user_id)

    case result do
      :ok ->
        conn
        |> resp(204, "")

      nil ->
        conn
        |> resp(404, "")
    end
  end

  def index(%{assigns: %{current_user: user}} = conn, %{"user_id" => user_id} = params) do
    user = Flight.Repo.preload(user, :school)
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    page = Document.documents_by_page(user_id, page_params, search_term)
    render(conn, "index.json", page: page, timezone: user.school.timezone)
  end

  defp authorize_student(
         %{assigns: %{current_user: user}, params: %{"user_id" => user_id}} = conn,
         params
       ) do
    cond do
      Accounts.has_role?(user, "student") and Integer.to_string(user.id) == user_id ->
        conn

      true ->
        authorize_admin(conn, params)
    end
  end

  defp authorize_admin(%{params: %{"user_id" => user_id}} = conn, _) do
    user = Accounts.get_user(user_id, conn)

    conn
    |> halt_unless_user_can?([
      Flight.Auth.Permission.new(:documents, :modify, :all)
    ])
    |> halt_unless_right_school(user.school_id)
  end

  defp halt_unless_right_school(%{assigns: %{current_user: user}} = conn, school_id) do
    cond do
      !Accounts.is_superadmin?(user) && user.school_id != school_id ->
        halt_unauthorized_response(conn)

      true ->
        conn
    end
  end
end
