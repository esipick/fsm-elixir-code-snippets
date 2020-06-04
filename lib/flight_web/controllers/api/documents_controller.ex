defmodule FlightWeb.API.DocumentController do
  use FlightWeb, :controller

  alias FlightWeb.ViewHelpers
  alias Flight.Auth.Permission

  alias Flight.Accounts
  alias Accounts.Document
  alias Flight.Repo

  plug(:authorize_view when action in [:index])
  plug(:authorize_modify when action in [:create, :delete, :update])

  def create(%{assigns: %{current_user: user}} = conn, %{
        "document" => document_params,
        "user_id" => user_id
      }) do
    user = Repo.preload(user, :school)
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

  def update(%{assigns: %{current_user: user}} = conn, %{
        "id" => id,
        "user_id" => user_id,
        "document" => document_params
      }) do
    document = Repo.get(Document, id)
    user = Repo.preload(user, :school)
    params = Map.put(document_params, "user_id", user_id)

    case Document.update_document(document, params) do
      {:ok, document} ->
        render(conn, "show.json", document: document, timezone: user.school.timezone)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(422)
        |> json(%{
          error: %{message: "Could not save document. Please correct errors in the form."},
          errors: ViewHelpers.translate_errors(changeset)
        })
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
    user = Repo.preload(user, :school)
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    page = Document.documents_by_page(user_id, page_params, search_term)
    render(conn, "index.json", page: page, timezone: user.school.timezone)
  end

  defp authorize_modify(%{params: %{"user_id" => user_id}} = conn, _) do
    user = Accounts.get_user(user_id, conn)

    conn
    |> halt_unless_user_can?([
      Flight.Auth.Permission.new(:documents, :modify, :all)
    ])
    |> halt_unless_right_school(user.school_id)
  end

  defp authorize_view(
         %{assigns: %{current_user: user}, params: %{"user_id" => user_id}} = conn,
         _params
       ) do
    conn
    |> halt_unless_user_can?([
      Permission.new(:documents, :view, :all),
      Permission.new(:documents, :view, {:personal, user_id})
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
