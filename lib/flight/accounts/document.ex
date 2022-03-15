defmodule Flight.Accounts.Document do
  use Ecto.Schema
  use Waffle.Ecto.Schema

  require Ecto.Query
  import Ecto.Query
  import Flight.Repo
  import Ecto.Changeset

  alias __MODULE__
  alias Ecto.Multi
  alias Flight.DocumentUploader

  @allowed_file_types ["image/png", "image/jpeg", "application/pdf"]

  schema "documents" do
    field(:expires_at, :date)
    field(:title, :string)
    field(:file, DocumentUploader.Type)
    belongs_to(:user, Flight.Accounts.User)

    timestamps()
  end

  def changeset(document \\ %Document{}, attrs) do
    document
    |> cast(attrs, [:expires_at, :title, :user_id])
    |> validate_required([:user_id])
  end

  def file_changeset(document, attrs) do
    document
    |> cast_attachments(attrs, [:file])
    |> validate_type(attrs)
    |> validate_file_size(attrs)
    |> validate_required([:file])
  end

  def create_document(params) do
    Multi.new()
    |> Multi.insert(:document, changeset(params))
    |> Multi.update(:document_with_file, &file_changeset(&1.document, params))
    |> transaction()
  end

  def update_document(document, params) do
    changeset = Document.changeset(document, params)

    changeset =
      case params["file"] do
        %Plug.Upload{} -> changeset |> file_changeset(params)
        _ -> changeset
      end

    case update(changeset) do
      {:ok, new_document} ->
        if new_document.file.file_name != document.file.file_name,
          do: DocumentUploader.delete({document.file, document})

        {:ok, new_document}

      result ->
        result
    end
  end

  def delete_document(id, user_id) do
    document = get_by(Document, %{id: id, user_id: user_id})

    if document do
      case delete(document) do
        {:ok, _} -> DocumentUploader.delete({document.file, document})
        result -> result
      end
    end
  end

  def documents_by_page(user_id, page_params, search_term) do
    page =
      get_documents(user_id)
      |> Flight.Accounts.Search.Document.run(search_term)
      |> paginate(%{page_params | page_size: 10})

    case search_term do
      "" ->
        page

      _ ->
        count =
          Document
          |> where([d], d.user_id == ^user_id)
          |> aggregate(:count, :id)

        Map.put(page, :total_entries, count)
    end
  end

  def get_documents(user_id) do
    Document
    |> where([d], d.user_id == ^user_id)
    |> order_by([d], desc: d.id)
  end

  def file_url(document) do
    DocumentUploader.url({document.file, document}, :original, signed: true)
  end

  defp validate_file_size(document, %{"file" => file}) do
    {:ok, %{size: size}} = File.stat(file.path)

    file_size = Application.get_env(:flight, :file_size)
    human_size = Size.humanize!(file_size, spacer: "")

    case size > file_size do
      true -> add_error(document, :file, "size should not exceed #{human_size}")
      false -> document
    end
  end

  defp validate_type(document, %{"file" => file}) do
    case Enum.member?(@allowed_file_types, file.content_type) do
      true -> document
      false -> add_error(document, :file, "Should be \".jpg .pdf .png\" type.")
    end
  end
end
