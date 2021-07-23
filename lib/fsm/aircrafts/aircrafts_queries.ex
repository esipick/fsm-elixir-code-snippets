defmodule Fsm.Aircrafts.AircraftsQueries do
    import Ecto.Query, warn: false

    alias Fsm.Scheduling.Aircraft
    alias Fsm.Accounts.UserRole
    alias Fsm.Accounts.Role
    alias Fsm.SchoolScope
    alias Flight.Accounts.UserAircraft
    alias Fsm.Aircrafts.Engine
    alias Flight.Accounts.UserAircraft
    require Logger

    def get_aircraft_query(aircraft_id) do
      from ar in Aircraft,
        select: ar,
        where: ar.archived == false,
        where: ar.id == ^aircraft_id
    end

    def get_all_aircrafts_query do
      from ar in Aircraft,
        where: ar.archived == false,
        select: ar
    end

    def list_aircrafts_query(page, per_page, sort_field, sort_order, filter, school_context) do
      get_all_aircrafts_query()
      |> SchoolScope.scope_query(school_context)
      |> sort_by(sort_field, sort_order)
      |> sort_by(:name, sort_order)
      |> filter(filter, school_context)
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
      Logger.info "filter: #{inspect filter}"
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

    defp filter(query, %{assigned: true}=filter, %{context: %{current_user: %{id: user_id}}}=school_context) do
      queri =
        from(a in query,
          left_join: ua in UserAircraft, on: ua.aircraft_id == a.id,
          where: ua.user_id==^user_id)
      filter(queri, filter)
    end

    defp filter(query, filter, school_context) do
      filter(query, filter)
    end

    def search(query, %{search_criteria: _, search_term: ""}) do
      query
    end

    def search(query, %{search_criteria: search_criteria, search_term: search_term}) do
      case search_criteria do
        :name ->
          from s in query,
            where: ilike(s.name, ^"%#{search_term}%") or ilike(s.make, ^"%#{search_term}%")

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

        @doc """
    Returns query to get aircraft by user_id and aircraft_id
    """
    def get_user_aircraft_query(user_id, aircraft_id) do
      from a in Aircraft,
          inner_join: u in UserAircraft, on: a.id == u.aircraft_id,
          select: a,
          where: a.id == ^aircraft_id and u.user_id == ^user_id
    end

    @doc """
    Returns query to get aircraft engine which has is_tachometer as true
    """
    def get_tach_engine_query(aircraft_id) do
        from e in Engine,
            inner_join: a in Aircraft, on: a.id == e.aircraft_id,
            select: e,
            where: a.id == ^aircraft_id and e.is_tachometer == true
    end

end