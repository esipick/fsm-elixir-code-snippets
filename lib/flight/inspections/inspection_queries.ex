defmodule Flight.Inspections.Queries do
    import Ecto.Query, warn: false

    alias Flight.Utils
    alias Flight.Scheduling.Aircraft
    alias Flight.Inspections.{
        CheckList,
        Maintenance,
        MaintenanceCheckList,
        AircraftMaintenance
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
                    tach_time_remaining: m.tach_hours + am.start_tach_hours - a.last_tach_time,
                    days: fragment("DATE_PART('day', ?::timestamp - ?::timestamp)", m.due_date, m.ref_start_date),
                    days_remaining: fragment("DATE_PART('day', ?::timestamp - now()::timestamp)", m.due_date)
                } 

        query
        |> paginate(page, per_page)
        |> sort_maintenance_by(sort_field, sort_order)
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
                    aircraft_make: a.make,
                    aircraft_model: a.model,
                    curr_tach_time: a.last_tach_time,
                    due_date: m.due_date,
                    tach_time_remaining: m.tach_hours + am.start_tach_hours - a.last_tach_time,
                    days: fragment("DATE_PART('day', ?::timestamp - ?::timestamp)", m.due_date, m.ref_start_date),
                    days_remaining: fragment("DATE_PART('day', ?::timestamp - now()::timestamp)", m.due_date)
                } 

        query
        # |> paginate(page, per_page)
        |> sort_maintenance_by(sort_field, sort_order)
        |> filter_maintenance_by(filter)
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

    def delete_checklist_from_maintenance_query(m_id, checklist_ids) do
        from mc in MaintenanceCheckList,
            where: mc.maintenance_id == ^m_id and mc.checklist_id in ^checklist_ids
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
                from [m, _, _a] in query,
                    order_by: [{^sort_order, fragment("DATE_PART('day', ?::timestamp - now()::timestamp)", m.due_date)}]

            :tach_time_remaining ->
                sort_order = if sort_order == :asc, do: :asc_nulls_last, else: :desc_nulls_last
                
                from [m, am, a] in query,
                    order_by: [{^sort_order, fragment("? + ? - ?", m.tach_hours, am.start_tach_hours, a.last_tach_time)}]

            :due_date ->
                sort_order = if sort_order == :asc, do: :asc_nulls_last, else: :desc_nulls_last
                from [m, _am, _a] in query,
                    order_by: [{^sort_order, m.due_date}]

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
                    perc = 
                        case value do
                            "extream" -> 0
                            "high" -> 0.05
                            "normal" -> 0.10
                            "low" -> 0.20
                            _ -> 1.0
                        end
                    
                    if value == "lowest" do
                        # greater than or equal to 21 %
                        perc = 0.21
                        from [m, am, a] in query,
                        where: (m.tach_hours > 0 and fragment("((?+?-?)::float/?::float)>=?", m.tach_hours, am.start_tach_hours, a.last_tach_time, m.tach_hours, ^perc)) or
                                (not is_nil(m.due_date) and not is_nil(m.ref_start_date) and 
                                fragment("(DATE_PART('day',?::timestamp-now()::timestamp)/DATE_PART('day',?::timestamp-?::timestamp))>=?", m.due_date, m.due_date, m.ref_start_date, ^perc))

                    else
                        from [m, am, a] in query,
                        where: (m.tach_hours > 0 and fragment("((?+?-?)::float/?::float)<=?", m.tach_hours, am.start_tach_hours, a.last_tach_time, m.tach_hours, ^perc)) or
                                (not is_nil(m.due_date) and not is_nil(m.ref_start_date) and 
                                fragment("(DATE_PART('day',?::timestamp-now()::timestamp)/DATE_PART('day',?::timestamp-?::timestamp))<=?", m.due_date, m.due_date, m.ref_start_date, ^perc))
                    end
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
                            from [m, _, _] in  query,
                                where: m.due_date >= ^start_date and m.due_date <= ^end_date
                        status == "completed" && start_date ->
                            from [_m, am, _] in  query,
                                where: am.end_time >= ^start_date and am.end_time <= ^end_date 
                        true ->
                            query   
                    end                    

                :maintenance_name ->
                    from [m, _, _a] in query,
                        where: ilike(m.name, ^"%#{value}%")
    
                :aircraft_name ->
                    from [_, _, a] in query,
                        where: ilike(fragment("concat(?, ' ', ?)", a.make, a.model), ^"%#{value}%")  
                        
                :school_id ->
                    from [m, _, _a] in query,
                        where: m.school_id == ^value

                _ -> query
            end
        end)
    end
end