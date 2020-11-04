defmodule FsmWeb.GraphQL.Documents.DocumentsResolvers do
    alias Fsm.Documents
  
    require Logger

    def list_documents(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
      page = Map.get(args, :page)
      per_page = Map.get(args, :per_page)
      user_id = Map.get(args, :user_id)
      sort_field = Map.get(args, :sort_field) || :inserted_at
      sort_order = Map.get(args, :sort_order) || :desc
      filter = Map.get(args, :filter) || %{}
      documents = Documents.list_documents(user_id, page, per_page, sort_field, sort_order, filter, context)
      {:ok, documents}
    end

    def update_document(parent, args, %{context: %{current_user: user}} = context) do
      document = Map.get(args, :document_input)
      id = Map.get(document, :id)
      user_id = Map.get(args, :user_id)
      case Documents.update_document(id, document, user_id) do
        {:ok, document} ->
          {:ok, document}
        {:error, error} ->
           {:error, error}
      end
    end

    def delete_document(parent, args, %{context: %{current_user: user}} = context) do
      id = Map.get(args, :document_id)
      user_id = Map.get(args, :user_id)
      Documents.delete_document(id, user_id)
    end
  end
    