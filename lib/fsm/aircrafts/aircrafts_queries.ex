defmodule Fsm.Aircrafts.AircraftsQueries do
    @moduledoc false

    import Ecto.Query, warn: false

    alias Fsm.Aircrafts.Aircraft
    alias Fsm.Accounts.UserRole
    alias Fsm.Accounts.Role
    alias Fsm.SchoolScope

    require Logger

    def get_aircraft_query(aircraft_id) do
      from ar in Aircraft,
        select: ar,
        where: ar.id == ^aircraft_id
    end

    def get_all_aircrafts_query do
      from ar in Aircraft,
        select: ar
    end

    def list_aircrafts_query(page, per_page, sort_field, sort_order, filter, school_context) do
      get_all_aircrafts_query()
      |> SchoolScope.scope_query(school_context)
      |> sort_by(sort_field, sort_order)
      |> sort_by(:name, sort_order)
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

          :archived ->
            from g in query,
                 where: g.archived == ^value

          :ifr_certified ->
            from g in query,
                 where: g.ifr_certified == ^value

          :simulator ->
            from g in query,
                 where: g.simulator == ^value

          :blocked ->
            from g in query,
                 where: g.blocked == ^value

#          :archived ->
#
#            if value do
#              from q in query,
#                   where: q.archived == ^true
#            else
#              from q in query,
#                   where: q.archived == ^false
#            end

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
        :name ->
          from s in query,
               where: ilike(s.name, ^"%#{search_term}%")

        :make ->
          from s in query,
               where: ilike(s.make, ^"%#{search_term}%")

        :model ->
          from s in query,
               where: ilike(s.model, ^"%#{search_term}%")

        :serial_number ->
          from s in query,
               where: ilike(s.serial_number, ^"%#{search_term}%")

        :equipment ->
          from s in query,
               where: ilike(s.equipment, ^"%#{search_term}%")

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