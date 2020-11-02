defmodule Fsm.Documents.DocumentsQueries do
    @moduledoc false

    import Ecto.Query, warn: false

    alias Fsm.Schema.Document
    alias Fsm.SchoolScope

    require Logger

    def list_documents_query(user_id, page, per_page, sort_field, sort_order, filter, context) do
      from(d in Document, where: d.user_id == ^user_id)
      |> sort_by(sort_field, sort_order)
      |> filter(filter)
      |> search(filter)
      |> paginate(page, per_page)
    end

    defp sort_by(query, nil, nil) do
      query
    end

    defp sort_by(query, sort_field, sort_order) do
      from g in query,
           order_by: [{^sort_order, field(g, ^sort_field)}]
    end

    defp filter(query, nil) do
      query
    end

    defp filter(query, filter) do
      Logger.debug "filter: #{inspect filter}"
      Enum.reduce(filter, query, fn ({key, value}, query) ->
        case key do
          :id ->
            from g in query,
                 where: g.id == ^value
          _ ->
            query
        end
      end)
    end


    def search(query, %{search_criteria: _, search_term: ""}) do
      query
    end

    def search(query, %{search_criteria: search_criteria, search_term: search_term}) do
        from s in query,
        where: ilike(s.title, ^"%#{search_term}%")
    end

    def search(query, _) do
      query
    end

    def paginate(query, 0, 0) do
      query
    end

    def paginate(query, 0, size) do
      from query,
           limit: ^size
    end

    def paginate(query, page, size) do
      from query,
           limit: ^size,
           offset: ^((page-1) * size)
    end
end