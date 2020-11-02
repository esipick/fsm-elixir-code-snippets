defmodule FsmWeb.GraphQL.Documents.DocumentsTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Documents.DocumentsResolvers

  # Enum
  enum(:document_order_by, values: [:desc, :asc])
  enum(:document_search_criteria, values: [:title])
  enum(:document_sort_fields, values: [:expires_at, :title])
  # QUERIES
  object :documents_queries do
    @desc "Get documents"
    field :get_documents, list_of(:document) do
      arg(:user_id, non_null(:integer))
      arg(:page, :integer, default_value: 1)
      arg(:per_page, :integer, default_value: 100)
      arg(:sort_field, :document_sort_fields)
      arg(:sort_order, :document_order_by)
      arg(:filter, :documents_filters)

      middleware(Middleware.Authorize, [:admin, :dispatcher])
      resolve(&DocumentsResolvers.list_documents/3)
    end
  end

  # MUTATIONS
  object :documents_mutations do
  end

  # TYPES

  object :document do
    field(:expires_at, :string)
    field(:title, :string)
    field(:file, :string)
  end

  input_object :documents_filters do
    field(:id, :integer)
    field(:search_criteria, :document_search_criteria)
    field(:search_term, :string)
  end
end
