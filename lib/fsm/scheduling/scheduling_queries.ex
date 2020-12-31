defmodule Fsm.Scheduling.SchedulingQueries do
    @moduledoc false

    import Ecto.Query, warn: false

    alias Fsm.Accounts.User
    alias Fsm.Accounts.UserRole
    alias Fsm.Accounts.Role
    alias Fsm.Scheduling.Appointment
    alias Fsm.Scheduling.Aircraft
    alias Fsm.SchoolAssets.Room

    alias Fsm.SchoolScope

    require Logger

    def get_appointments_query(_context, :all) do
      from a in Appointment,
           left_join: u in User, on: a.user_id == u.id,
           left_join: i in User, on: a.instructor_user_id == i.id,
           left_join: ar in Aircraft, on: a.aircraft_id == ar.id,
           left_join: r in Room, on: a.room_id == r.id,
           left_join: s in Aircraft, on: a.simulator_id == s.id,
           where: a.archived == false,
           select: %{appointment: a, user: u, instructor: i, aircraft: ar, room: r, simulator: s}
    end

    def get_appointments_query(%{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}}=context, _) do
      from a in Appointment,
          left_join: u in User, on: a.user_id == u.id,
          left_join: i in User, on: a.instructor_user_id == i.id,
          left_join: ar in Aircraft, on: a.aircraft_id == ar.id,
          left_join: r in Room, on: a.room_id == r.id,
          left_join: s in Aircraft, on: a.simulator_id == s.id,
          where: a.archived == false and (a.user_id == ^id),
          select: %{appointment: a, user: u, instructor: i, aircraft: ar, room: r, simulator: s}
    end

    def get_appointment_query(id) do
      from a in Appointment,
          left_join: u in User, on: a.user_id == u.id,
          left_join: i in User, on: a.instructor_user_id == i.id,
          left_join: ar in Aircraft, on: a.aircraft_id == ar.id,
          left_join: r in Room, on: a.room_id == r.id,
          left_join: s in Aircraft, on: a.simulator_id == s.id,
          where: a.id == ^id,
          select: %{appointment: a, user: u, instructor: i, aircraft: ar, room: r, simulator: s}
    end

    defp show_appointments(roles) do
#      if is_list(roles) and roles != [] and
#         (Enum.member?(roles, "admin") or Enum.member?(roles, "dispatcher") or Enum.member?(roles, "instructor")) do
        :all

#      else
#        :personal
#      end
    end

    def list_appointments_query(page, per_page, sort_field, sort_order, filter, %{context: %{current_user: %{roles: roles}}} = school_context) do
      get_appointments_query(school_context, show_appointments(roles))
      |> SchoolScope.scope_query(school_context)
      |> sort_by(sort_field, sort_order)
      |> sort_by(:start_at, sort_order)
      |> filter(filter)
      |> search(filter)
      |> paginate(page, per_page)
    end

    def visible_air_assets_query(school_context, search_term \\ "") do
      aircraft_query(school_context, search_term)
      |> where([a], a.archived == false)
      |> order_by([a], asc: [a.make, a.model, a.tail_number, a.name])
    end

    def aircraft_query(school_context, search_term \\ "") do
      Aircraft
      |> Flight.Scheduling.Search.Aircraft.run(search_term)
      |> SchoolScope.scope_query(school_context)
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
            from a in query,
                 where: a.id == ^value
          :school_id ->
            from a in query,
                 where: a.school_id == ^value

          :user_id ->
            from a in query,
                 where: a.user_id == ^value

          :instructor_user_id ->
            from a in query,
                 where: a.instructor_user_id == ^value

          :aircraft_id ->
            from a in query,
                 where: a.aircraft_id == ^value

          :room_id ->
            from a in query,
                 where: a.room_id == ^value

          :archived ->
            from a in query,
                 where: a.archived == ^value

          :demo ->
            from a in query,
                 where: a.demo == ^value

          :upcoming ->
            if value do
              from a in query,
                   where: a.start_at >= ^NaiveDateTime.utc_now()
            else
              from a in query,
                   where: a.start_at < ^NaiveDateTime.utc_now()
            end

          :past ->
            if value do
              from a in query,
                   where: a.start_at < ^NaiveDateTime.utc_now()
            else
              from a in query,
                   where: a.start_at >= ^NaiveDateTime.utc_now()
            end

          :from ->
            from a in query,
                 where: a.start_at >= ^value

          :to ->
            from a in query,
                 where: a.start_at <= ^value

          :aircraft_id_is_not_null ->
            from a in query,
                where: not is_nil(a.aircraft_id)

          :room_id_is_not_null ->
            from a in query,
                where: not is_nil(a.room_id)

          :status ->
            from a in query,
                 where: a.status == ^value

          :type ->
            from a in query,
                 where: a.type == ^value

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
        :payer_name ->
          from a in query,
               where: ilike(a.payer_name, ^"%#{search_term}%")

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