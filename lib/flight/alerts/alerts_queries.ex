defmodule Flight.Alerts.AlertsQueries do
    import Ecto.Query, warn: false

    alias Flight.Alerts.Alert
    alias Flight.SchoolScope
    require Logger

    def get_all_alerts_query do
        from ar in Alert,
          select: ar
    end

    def list_alerts_query(page, per_page, sort_field, sort_order, filter, school_context) do
        get_all_alerts_query()
        |> SchoolScope.scope_query(school_context)
        |> sort_by(sort_field, sort_order)
        |> sort_by(:updated_at, sort_order)
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

    def search(query, %{search_criteria: _, search_term: ""}) do
        query
    end

    def search(query, %{search_criteria: search_criteria, search_term: search_term}) do
        case search_criteria do
            :title ->
            from s in query,
                    where: ilike(s.title, ^"%#{search_term}%")

            :description ->
            from s in query,
                    where: ilike(s.description, ^"%#{search_term}%")

            _ ->
            query
        end
    end

    def search(query, _) do
        query
    end

    defp filter(query, nil) do
        query
    end

    defp filter(query, filter) do
        Logger.debug "filter: #{inspect filter}"
        Enum.reduce(filter, query, fn ({key, value}, query) ->
            case key do
            :title ->
                from g in query,
                where: g.title == ^ value

            :code ->
                from g in query,
                where: g.code == ^ value

            :priority ->
                from g in query,
                where: g.priority == ^ value

            :is_read ->
                from g in query,
                where: g.is_read == ^ value

            _ ->
            query
            end
        end)
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
