defmodule Fsm.SchoolAssets.SchoolAssetsQueries do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  alias Fsm.SchoolScope
  alias Fsm.SchoolAssets.Room

  require Logger

  def list_rooms_query(page, per_page, sort_field, sort_order, filter, school_context) do
    Room
    |> SchoolScope.scope_query(school_context)
    |> sort_by(sort_field, sort_order)
    |> filter(filter)
    |> search(filter)
    |> paginate(page, per_page)
  end

  def get_room(id, school_context) do
    Room
    |> SchoolScope.scope_query(school_context)
    |> where([r], r.id == ^id and r.archived == false)
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
    #Logger.info "filter: #{inspect filter}"
    Enum.reduce(filter, query, fn ({key, value}, query) ->
      case key do
        :capacity ->
          from g in query,
               where: g.capacity == ^value

        :archived ->
          from g in query,
               where: g.archived == ^value

        _ ->
          query
      end
    end)
  end

  def search(query, %{search_criteria: _, search_term: ""}) do
    query
  end

  def search(query, %{search_criteria: search_criteria, search_term: search_term}) do
    case search_criteria do
      :location ->
        from s in query,
             where: ilike(s.location, ^"%#{search_term}%")

      :resources ->
        from s in query,
             where: ilike(s.resources, ^"%#{search_term}%")

      _ ->
        query
    end
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
