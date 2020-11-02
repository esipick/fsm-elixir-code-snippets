defmodule Fsm.Documents do
    import Ecto.Query, warn: false

    alias Flight.Repo
    alias Fsm.Documents.DocumentsQueries
  
    require Logger
  
    def list_documents(user_id, page, per_page, sort_field, sort_order, filter, context) do
        DocumentsQueries.list_documents_query(user_id, page, per_page, sort_field, sort_order, filter, context)
        |> Repo.all()
    end
  end
  