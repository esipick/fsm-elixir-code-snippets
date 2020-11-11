defmodule Fsm.Documents do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Fsm.Documents.DocumentsQueries
  alias Fsm.DocumentUploader
  alias Fsm.Schema.Document
  require Logger

  def list_documents(user_id, page, per_page, sort_field, sort_order, filter, context) do
    DocumentsQueries.list_documents_query(
      user_id,
      page,
      per_page,
      sort_field,
      sort_order,
      filter,
      context
    )
    |> Repo.all()
    |> case do
      nil ->
        nil

      documents ->
        documents
        |> Enum.map(fn document ->
          %{
            expires_at: document.expires_at,
            file: %{name: document.file.file_name, url: get_file_url(document)},
            id: document.id,
            title: document.title || document.file.file_name
          }
        end)
    end
  end

  def get_file_url(document) do
    DocumentUploader.url({document.file, document})
  end

  def delete_document(id, user_id) do
    document = Repo.get_by(Fsm.Schema.Document, %{id: id, user_id: user_id})

    if document do
      document
      |> Repo.delete
      |> case do
        {:ok, _} -> 
          DocumentUploader.delete({document.file, document})
          {:ok, :deleted}
        _-> {:error, :failed}
      end
    else
      {:error, :not_found}
    end
  end

  def update_document(id, params, user_id) do
    document =
    Repo.get(Document, id)
    |> case do
        nil -> {:error, :document_not_found}
        document -> 
            changeset = Fsm.Schema.Document.changeset(document, params)
    
            changeset
            |> Repo.update()
            |> case do
                {:ok, new_document} ->

                    new_document = %{
                    expires_at: new_document.expires_at,
                    id: new_document.id,
                    title: new_document.title,
                    file: %{
                      name: document.file.file_name,
                      url: get_file_url(new_document)
                    }
                        }
                    {:ok, new_document}
    
                result ->
                    result
            end
       end
   end
end
