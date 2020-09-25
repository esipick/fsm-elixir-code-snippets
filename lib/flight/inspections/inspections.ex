defmodule Flight.Inspections do
    alias Flight.Repo

    alias Flight.Scheduling.Aircraft
    alias Flight.Ecto.Errors
    alias Flight.Inspections.{
        Queries,
        CheckList,
        Maintenance,
        MaintenanceAlert,
        AircraftMaintenance,
        MaintenanceCheckList
    }

    def get_all_maintenance(page, per_page, sort_field, sort_order, filter) do
        Queries.get_all_maintenance_query(page, per_page, sort_field, sort_order, filter)
        |> Repo.all
        |> transform_maintenance
    end

    def get_aircraft_maintenance(aircraft_id, sort_field, sort_order, filter) do
        Repo.get(Aircraft, aircraft_id)
        |> case do
            %{id: id} ->
                filter = Map.put(filter, :aircraft_id, id)

                {:ok, Repo.all(Queries.get_aircraft_maintenance(sort_field, sort_order, filter))}

            _ -> {:error, "Aircraft with id: #{aircraft_id} not found."}
        end
    end

    def get_maintenance_assoc(id) do
        with {:ok, changeset} <- get_maintenance(%{id: id}) do
            {:ok, Repo.preload(changeset, :checklists)}
        end
    end

    def get_maintenance(filter) do
        filter
        |> Queries.get_maintenance_query
        |> Ecto.Query.first
        |> Repo.get_by([])
        |> case do
            nil -> {:error, "Maintenance Not found"}
            item -> {:ok, item}
        end
    end

    def create_and_schedule_maintenance(_aircraft_ids, [], _alerts, _params), do: {:error, "No CheckList being added."}
    def create_and_schedule_maintenance([], _checklist_ids, _alerts, _params), do: {:error, "No Aircraft & hours being assigned."}
    def create_and_schedule_maintenance(aircraft_hours, checklist_ids, alerts, params) do
        checklist_ids = MapSet.to_list(MapSet.new(checklist_ids))
        
        Repo.transaction(fn -> 
            with {:ok, %{id: id} = maintenance} <- create_maintenance(params),
                {:ok, :done} <- add_alerts_to_maintenance(maintenance, alerts),
                {:ok, :done} <- assign_maintenance_to_aircrafts(id, aircraft_hours) do
                add_checklists_to_maintenance(id, checklist_ids)
    
                {:ok, maintenance}

            else
                {:error, error} -> Repo.rollback(error) 
            end
        end)
    end

    def create_maintenance(params) do
        %Maintenance{}
        |> Maintenance.changeset(params)
        |> Repo.insert
    end

    def update_maintenance(id, params) do
        with {:ok, maintenance} <- get_maintenance(%{id: id}) do
            maintenance
            |> Maintenance.changeset(params)
            |> Repo.update
        end
    end

    def delete_maintenance(id, school_id) do
        with {:ok, maintenance} <- get_maintenance(%{id: id, school_id: school_id}) do
            Repo.delete(maintenance)
        end
    end 

    '''
    CheckLists
    '''

    def get_all_checklists(page, per_page, sort_field, sort_order, filter) do
        Queries.get_all_checklists_query(page, per_page, sort_field, sort_order, filter)
        |> Repo.all
        |> Enum.map(&(Map.take(&1, CheckList.__schema__(:fields))))
    end

    def get_checklist_categories() do
        CheckList.categories()
    end

    def create_checklist(_school_id, []), do: {:ok, []}
    def create_checklist(school_id, params) when is_map(params) do
        create_checklist(school_id, [params])
    end

    def create_checklist(school_id, params) do
        # school = Accounts.get_school(school_id)

        Repo.transaction(fn -> 
            Enum.reduce_while(params, [], fn(item, acc) -> 
                %CheckList{}
                |> CheckList.changeset(Map.put(item, "school_id", school_id))
                |> Repo.insert
                |> case do
                    {:ok, changeset} -> 
                        {:cont, [changeset | acc]}

                    {:error, error} ->
                        {:halt, {:error, "#{Map.get(item, "name")} #{Errors.traverse(error)}"}}
                    end
            end)
            |> case do
                {:error, error} -> Repo.rollback(error)
                result -> result
            end
        end)
    end

    def add_checklists_to_maintenance(school_id, maintenance_id, checklists) do
        checklist_ids = Enum.filter(checklists, &(is_binary(&1)))
        checklists = checklists -- checklist_ids

        with {:ok, checklists} <- create_checklist(school_id, checklists) do
            newly_added_ids = Enum.map(checklists, &(&1.id))
            ids = checklist_ids ++ newly_added_ids

            add_checklists_to_maintenance(maintenance_id, ids)
        end
    end

    def add_checklists_to_maintenance(maintenance_id, checklists) do
        items = Enum.map(checklists, &(%{maintenance_id: maintenance_id, checklist_id: &1}))
        Repo.insert_all(MaintenanceCheckList, items, on_conflict: :nothing, conflict_target: [:maintenance_id, :checklist_id])
    
        {:ok, :done}
    end

    def delete_checklist(id) do
        with %{id: _} = changeset <- Repo.get(CheckList, id) do
            Repo.delete(changeset)

        else
            nil -> {:error, "Checklist with id: #{id} not found."}
        end
    end

    def delete_checklist_from_maintenance(_m_id, []), do: {:ok, :done}
    def delete_checklist_from_maintenance(m_id, checklist_ids) do
        Queries.delete_checklist_from_maintenance_query(m_id, checklist_ids)
        |> Repo.delete_all(checklist_ids)

        {:ok, :done}
    end

    '''
        Maintenance Alerts
    '''

    def add_alerts_to_maintenance(_maintenance_id, []), do: {:ok, :done}
    def add_alerts_to_maintenance(%{id: id} = _maintenance, alerts) do
        params = 
            Enum.map(alerts, fn(item) -> 
                MaintenanceAlert.changeset(%MaintenanceAlert{}, Map.put(item, "maintenance_id", id)) 
            end)

        valid = Enum.all?(params, &(&1.valid?))

        if valid do
            params = Enum.map(params, &(&1.changes))
            {_, _} = Repo.insert_all(MaintenanceAlert, params)
            {:ok, :done}

        else
            {:error, "Something wrong with alerts, Please check and try again."}
        end
    end

    def remove_aircrafts_from_maintenance(_maintenance_id, []), do: {:ok, :done}
    def remove_aircrafts_from_maintenance(maintenance_id, aircraft_ids) do
        Queries.delete_aircrafts_from_maintenance_query(maintenance_id, aircraft_ids)
        |> Repo.delete_all(aircraft_ids)

        {:ok, :done}
    end

    def assign_maintenance_to_aircrafts_transaction(m_id, aircraft_hours) when is_map(aircraft_hours), do: assign_maintenance_to_aircrafts_transaction(m_id, [aircraft_hours])
    def assign_maintenance_to_aircrafts_transaction(m_id, aircraft_hours) do
        Repo.transaction(fn -> 
            assign_maintenance_to_aircrafts(m_id, aircraft_hours)
            |> case do
                {:error, error} -> Repo.rollback(error)
                {:ok, result} -> result
            end
        end)
    end

    defp assign_maintenance_to_aircrafts(m_id, aircraft_hours) do 
        aircraft_hours
        |> MapSet.new
        |> MapSet.to_list
        |> Enum.reduce_while({:ok, :done}, fn(item, _acc) -> 
            %AircraftMaintenance{}
            |> AircraftMaintenance.changeset(Map.put(item, "maintenance_id", m_id))
            |> Repo.insert
            |> case do
                {:ok, _} -> {:cont, {:ok, :done}}
                {:error, changeset} -> 
                    error = Flight.Ecto.Errors.traverse(changeset)
                    {:halt, {:error, error}}
            end 
        end)
    end

    def transform_maintenance(maintenance) when is_list(maintenance) do
        Enum.map(maintenance, &(transform_maintenance(&1)))
    end

    def transform_maintenance(%{
        status: status,
        tach_hours: tach_hours,
        tach_time_remaining: remaining_tach_hours,
        days: days,
        days_remaining: remaining_days} = maintenance) do
            tach_hours = tach_hours || 0
            days = days || 0

            remaining_percent =
                cond do
                    tach_hours > 0 and remaining_tach_hours <= 0 -> 0
                    tach_hours > 0 and remaining_tach_hours > 0 -> remaining_tach_hours / tach_hours
                    days > 0 and remaining_days <= 0 -> 0
                    days > 0 and remaining_days > 0 -> remaining_days / days
                    true -> 1
                end

            color =
                cond do
                    remaining_percent <= 0 -> "#ff1414"
                    remaining_percent < 0.05 -> "#fffb14"
                    remaining_percent < 0.1 -> "#ff8e14"
                    remaining_percent < 0.2 -> "#14ff5f"
                    true -> "#6ae6b4" # greater than 21
                end

            color = 
                if status != "pending", do: "#28940a", else: color
            Map.put(maintenance, :status_color, color)
    end

end