defmodule Flight.Inspections.Queries do
    import Ecto.Query, warn: false
    alias Flight.Inspections.{
        CheckList
    }

    def get_all_checklists_query(page, per_page, sort_field, sort_order, filter) do
        query = 
            from c in CheckList, select: c

        query
        |> paginate(page, per_page)
        |> sort_by(sort_field, sort_order)
        |> filter_by(filter)
    end

    defp paginate(query, page, per_page) when is_nil(page) or is_nil(per_page), do: query
    defp paginate(query, page, per_page) do
        from q in query,
            offset: ^page,
            limit: ^per_page
    end

    defp sort_by(query, sort_field, sort_order) when is_nil(sort_field) or is_nil(sort_order), do: query
    defp sort_by(query, sort_field, sort_order) do
        from q in query,
         order_by: [{^sort_order, field(q, ^sort_field)}]
    end

    defp filter_by(query, nil), do: query 
    defp filter_by(query, filter) do
        Enum.reduce(filter, query, fn({key, value}, query) -> 
            case key do
                _ -> query
            end
        end)
    end
end