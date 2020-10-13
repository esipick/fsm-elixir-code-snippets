defmodule Flight.Inspections.Queries do
    import Ecto.Query, warn: false

    alias Flight.Utils
    alias Flight.Scheduling.Aircraft
    alias Flight.Inspections.{
        Squawk,
        CheckList,
        Maintenance,
        SquawkAttachment,
        CheckListDetails,
        CheckListLineItem,
        MaintenanceCheckList,
        AircraftMaintenance,
        AircraftMaintenanceAttachment
    }

    def get_maintenance_query(filter) do
        query = 
            from m in Maintenance,
                select: m

        filter_by(query, filter)
    end

    # filter based on status, i-e not completed.
    def get_all_maintenance_query(page, per_page, sort_field, sort_order, filter) do
        query = 
            from m in Maintenance,
                inner_join: am in AircraftMaintenance, on: am.maintenance_id == m.id,
                inner_join: a in Aircraft, on: a.id == am.aircraft_id,
                select: %{
                    name: m.name,
                    aircraft_id: a.id,
                    maintenance_id: m.id,
                    status: am.status,
                    tach_hours: m.tach_hours,
                    aircraft_make: a.make,
                    aircraft_model: a.model,
                    curr_tach_time: a.last_tach_time,
                    due_date: m.due_date,
                    tach_time_remaining: am.due_tach_hours - a.last_tach_time,
                    days: fragment("DATE_PART('day', ?::timestamp - ?::timestamp)", m.due_date, m.ref_start_date),
                    days_remaining: fragment("DATE_PART('day', ?::timestamp - now()::timestamp)", am.due_date)
                },
                where: a.archived == false and a.simulator == false

        query
        |> paginate(page, per_page)
        |> sort_maintenance_by(sort_field, sort_order)
        |> filter_maintenance_by(filter)
    end

    def get_aircraft_maintenance_query(filter) do
        query = 
            from m in Maintenance,
                inner_join: am in AircraftMaintenance, on: am.maintenance_id == m.id,
                inner_join: a in Aircraft, on: a.id == am.aircraft_id,
                select: %{
                    name: m.name,
                    aircraft_id: a.id,
                    maintenance_id: m.id,
                    status: am.status,
                    tach_hours: m.tach_hours,
                    # aircraft_make: a.make,
                    # aircraft_model: a.model,
                    curr_tach_time: a.last_tach_time,
                    due_date: m.due_date,
                    tach_time_remaining: am.due_tach_hours - a.last_tach_time,
                    days: fragment("DATE_PART('day', ?::timestamp - ?::timestamp)", m.due_date, m.ref_start_date),
                    days_remaining: fragment("DATE_PART('day', ?::timestamp - now()::timestamp)", am.due_date)
                },
                where: a.archived == false and a.simulator == false

        query
        |> filter_maintenance_by(filter)
        
    end

    def get_aircraft_maintenance(sort_field, sort_order, filter) do
        query = 
            from m in Maintenance,
                inner_join: am in AircraftMaintenance, on: am.maintenance_id == m.id,
                inner_join: a in Aircraft, on: a.id == am.aircraft_id,
                select: %{
                    name: m.name,
                    aircraft_id: a.id,
                    maintenance_id: m.id,
                    status: am.status,
                    tach_hours: m.tach_hours,
                    # aircraft_make: a.make,
                    # aircraft_model: a.model,
                    curr_tach_time: a.last_tach_time,
                    due_date: m.due_date,
                    tach_time_remaining: am.due_tach_hours - a.last_tach_time,
                    days: fragment("DATE_PART('day', ?::timestamp - ?::timestamp)", m.due_date, m.ref_start_date),
                    days_remaining: fragment("DATE_PART('day', ?::timestamp - now()::timestamp)", am.due_date)
                },
                where: a.archived == false and a.simulator == false

        query
        |> sort_maintenance_by(sort_field, sort_order)
        |> filter_maintenance_by(filter)
    end

    def get_all_squawks_query(page, per_page, sort_field, sort_order, filter) do
        query =
            from s in Squawk,
                inner_join: a in Aircraft, on: a.id == s.aircraft_id,
                select: %{
                    title: s.title,
                    description: s.description,
                    aircraft_id: a.id,
                    maintenance_id: s.id,
                    aircraft_make: a.make,
                    aircraft_model: a.model,
                    curr_tach_time: a.last_tach_time,
                    due_date: s.created_at,
                    resolved_at: s.resolved_at
                }
        
        query
        |> paginate(page, per_page)
        |> sort_squawks_by(sort_field, sort_order)
        |> filter_squawks_by(filter)
    end

    def get_all_checklists_query(page, per_page, sort_field, sort_order, filter) do
        query = 
            from c in CheckList, select: c

        query
        |> paginate(page, per_page)
        |> sort_by(sort_field, sort_order)
        |> filter_by(filter)
    end

    def delete_aircrafts_from_maintenance_query(m_id, aircraft_ids) do
        from am in AircraftMaintenance,
            where: am.maintenance_id == ^m_id and am.aircraft_id in ^aircraft_ids
    end

    def get_aircraft_maintenance_attachment_query(filter) do
        query = 
            from ama in AircraftMaintenanceAttachment,
                inner_join: am in AircraftMaintenance, on: ama.aircraft_maintenance_id == am.id,
                inner_join: m in Maintenance, on: am.maintenance_id == m.id, 
                select: ama

        filter_by(query, filter)
    end

    def delete_checklist_from_maintenance_query(m_id, checklist_ids) do
        from mc in MaintenanceCheckList,
            where: mc.maintenance_id == ^m_id and mc.checklist_id in ^checklist_ids
    end

    def squawk_attachment_query(id, squawk_id, school_id) do
        from st in SquawkAttachment,
            inner_join: s in Squawk, on: s.id == st.squawk_id,
            select: st,
            where: st.squawk_id == ^squawk_id and st.id == ^id and s.school_id == ^school_id
    end

    def validate_aircraft_checklist_maintenance_query(mc_id, am_id) do
        from mc in MaintenanceCheckList,
            inner_join: am in AircraftMaintenance, on: am.maintenance_id == mc.maintenance_id,
            select: %{maintenance_id: mc.maintenance_id},
            where: mc.id == ^mc_id and am.id == ^am_id
    end

    def get_all_aircrafts_query(filter) do
        query =
            from a in Aircraft,
                select: a

        filter_by(query, filter)
    end

    def get_checklist_query(m_id, aircraft_id) do
        from c in CheckList,
            inner_join: mc in MaintenanceCheckList, on: mc.checklist_id == c.id,
            inner_join: am in AircraftMaintenance, on: am.maintenance_id == mc.maintenance_id,
            select: %{
                name: c.name,
                maintenance_checklist_id: mc.id,
                aircraft_maintenance_id: am.id
            },
            where: mc.maintenance_id == ^m_id and am.aircraft_id == ^aircraft_id and is_nil(am.start_et) # wanna get pending maintenance checklists
    end

    def get_checklist_items_query(filter) do
        query = 
            from cd in CheckListDetails,
                left_join: cli in CheckListLineItem, on: cli.checklist_details_id == cd.id,
                select: %{
                    maintenance_checklist_id: cd.maintenance_checklist_id,
                    aircraft_maintenance_id: cd.aircraft_maintenance_id,
                    status: cd.status,
                    line_items: fragment("array_agg(?)", cli.part_name)
                },
                group_by: cd.id

        query
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
                :school_id ->
                    from q in query,
                        where: q.school_id == ^value

                :id ->
                    from q in query,
                        where: q.id == ^value

                :squawk_id ->
                    from q in query,
                        where: q.squawk_id == ^value

                :ids ->
                    from q in query,
                        where: q.id in ^value

                :attachment_school_id -> 
                    from [_, _, m] in query,
                        where: m.school_id == ^value

                :maintenance_checklist_ids -> 
                    from q in query,
                        where: q.maintenance_checklist_id in ^value

                :aircraft_maintenance_ids ->
                    from q in query,
                        where: q.aircraft_maintenance_id in ^value

                _ -> query
            end
        end)
    end

    defp sort_maintenance_by(query, sort_field, sort_order) when is_nil(sort_field) or is_nil(sort_order), do: query
    defp sort_maintenance_by(query, sort_field, sort_order) do

        case sort_field do
            :aircraft_name ->
                from [_m, _, a] in query,
                    order_by: [{^sort_order, field(a, ^:model)}, {^sort_order, field(a, ^:make)}]

            :name ->
                from [m, _, _a] in query,
                    order_by: [{^sort_order, field(m, ^sort_field)}]

            :curr_tach_time ->
                from [_m, _, a] in query,
                    order_by: [{^sort_order, field(a, ^:last_tach_time)}]

            :days_remaining ->
                sort_order = if sort_order == :asc, do: :asc_nulls_last, else: :desc_nulls_last
                from [_m, am, _a] in query,
                    order_by: [{^sort_order, fragment("DATE_PART('day', ?::timestamp - now()::timestamp)", am.due_date)}]

            :tach_time_remaining ->
                sort_order = if sort_order == :asc, do: :asc_nulls_last, else: :desc_nulls_last
                
                from [_m, am, a] in query,
                    order_by: [{^sort_order, fragment("? - ?", am.due_tach_hours, a.last_tach_time)}]

            :due_date ->
                sort_order = if sort_order == :asc, do: :asc_nulls_last, else: :desc_nulls_last
                from [_m, am, _a] in query,
                    order_by: [{^sort_order, am.due_date}]

            _ -> query
        end
    end

    defp filter_maintenance_by(query, nil), do: query 
    defp filter_maintenance_by(query, filter) do
        Enum.reduce(filter, query, fn({key, value}, query) -> 
            case key do
                :aircraft_id ->
                    from [m, am] in query,
                        where: am.aircraft_id == ^value

                :status -> 
                    from [_, am, _] in query,
                        where: am.status == ^value
                
                :urgency -> # #can only be applied when status is pending, [extream, high, normal, low, lowest]
                    {low_perc, high_perc} = 
                        case value do
                            "extream" -> {0, 0}
                            "high" -> {0.01, 0.05}
                            "normal" -> {0.09, 0.10}
                            "low" -> {0.11, 0.20}
                            _ -> {0.21, 1000000.0}
                        end
                    
                    from [m, am, a] in query,
                        where: (m.tach_hours > 0 and fragment("((?-?)::float/?::float) BETWEEN ? AND ?", am.due_tach_hours, a.last_tach_time, m.tach_hours, ^low_perc, ^high_perc)) or
                            (not is_nil(am.due_date) and not is_nil(am.start_date) and 
                            fragment("(DATE_PART('day',?::timestamp-now()::timestamp)/DATE_PART('day',?::timestamp-?::timestamp)) BETWEEN ? AND ?", am.due_date, am.due_date, am.start_date, ^low_perc, ^high_perc))

                :occurance ->
                    now = NaiveDateTime.utc_now()
                    # can be any_time, past_week, past_month, past_year, current_week, current_month, current_year. "1596561995-1596562995"
                    {start_date, end_date} =
                        case value do
                            "past_week" -> {Utils.beginning_of_last_week(), Utils.end_of_last_week()}
                            "past_month" -> {Utils.beginning_of_last_month(), Utils.end_of_last_month()}
                            "past_year" -> {Utils.beginning_of_last_year(), Utils.end_of_last_year()}
                            "current_week" -> {Timex.beginning_of_week(now), Timex.end_of_week(now)}
                            "current_month" -> {Timex.beginning_of_month(now), Timex.end_of_month(now)}
                            "current_year" -> {Timex.beginning_of_year(now), Timex.end_of_year(now)}
                            "any_time" -> {nil, nil}
                            _ -> Utils.date_range_from_str(value) 
                        end
                    
                    status = Map.get(filter, :status) || "pending"
                    cond do
                        status == "pending" && start_date ->
                            from [m, am, _] in  query,
                                where: am.due_date >= ^start_date and am.due_date <= ^end_date

                        status == "completed" && start_date ->
                            from [_m, am, _] in  query,
                                where: am.end_et >= ^start_date and am.end_et <= ^end_date 
                        true ->
                            query   
                    end                    

                :name ->
                    from m in query,
                        where: ilike(m.name, ^"%#{value}%")
    
                :aircraft_name ->
                    from [_, _, a] in query,
                        where: ilike(fragment("concat(?, ' ', ?)", a.make, a.model), ^"%#{value}%")  
                        
                :school_id ->
                    from [m, _, _a] in query,
                        where: m.school_id == ^value

                :id ->
                    from q in query,
                        where: q.id == ^value

                _ -> query
            end
        end)
    end

    defp sort_squawks_by(query, sort_field, sort_order) when is_nil(sort_field) or is_nil(sort_order), do: query
    defp sort_squawks_by(query, sort_field, sort_order) do
        case sort_field do
            :aircraft_name ->
                from [_s, a] in query,
                    order_by: [{^sort_order, field(a, ^:model)}, {^sort_order, field(a, ^:make)}]

            :status ->
                from [s, _a] in query,
                    order_by: [{^sort_order, s.resolved_at}]
            
            :name -> 
                from [s, _a] in query,
                    order_by: [{^sort_order, s.description}]
            
            :date -> 
                from [s, _q] in query,
                    order_by: [{^sort_order, s.created_at}]

            :curr_tach_time ->
                from [_s, a] in query,
                    order_by: [{^sort_order, field(a, ^:last_tach_time)}]

            _ -> query

        end
    end

    defp filter_squawks_by(query, nil), do: query 
    defp filter_squawks_by(query, filter) do
        Enum.reduce(filter, query, fn({key, value}, query) -> 
            case key do
                :aircraft_id ->
                    from [s, _a] in query,
                        where: s.aircraft_id == ^value

                :school_id ->
                    from [s, _a] in query,
                        where: s.school_id == ^value

                :status -> 
                    
                    if value == "pending" do
                        from [s, _a] in query,
                            where: is_nil(s.resolved_at)
                    else
                        from [s, _a] in query,
                            where: not is_nil(s.resolved_at)
                    end

                _ -> query
            end
        end)
    end
end