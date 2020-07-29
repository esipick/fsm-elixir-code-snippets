defmodule Flight.Inspections do
    alias Flight.Repo

    alias Flight.Accounts
    alias Flight.Inspections.{
        Queries,
        CheckList,
        Maintenance,
        MaintenanceAlert,
        AircraftMaintenance,
        MaintenanceCheckList
    }

    def get_all_maintenance(sort_field, sort_order, filter) do
        {:ok, []}
    end

    def get_maintenance_assoc(id) do
        with {:ok, changeset} <- get_maintenance(id) do
            {:ok, Repo.preload(changeset, :checklists)}
        end
    end

    def get_maintenance(id) do
        Repo.get(Maintenance, id)
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
        with {:ok, maintenance} <- get_maintenance(id) do
            maintenance
            |> Maintenance.changeset(params)
            |> Repo.update
        end
    end

    def delete_maintenance(id) do
        with {:ok, maintenance} <- get_maintenance(id) do
            Repo.delete(maintenance)
        end
    end 

    '''
    CheckLists
    '''

    def get_all_checklists(page, per_page, sort_field, sort_order, filter) do
        checklists = 
            Queries.get_all_checklists_query(page, per_page, sort_field, sort_order, filter)
            |> Repo.all
            |> Enum.map(&(Map.take(&1, CheckList.__schema__(:fields))))
    end

    def create_checklist(_school_id, []), do: {:ok, []}
    def create_checklist(school_id, params) when is_map(params) do
        create_checklist(school_id, [params])
    end

    def create_checklist(school_id, params) do
        school = Accounts.get_school(school_id)

        Repo.transaction(fn -> 
            Enum.reduce_while(params, [], fn(item, acc) -> 
                %CheckList{}
                |> CheckList.changeset(Map.put(item, "school_id", school_id))
                |> Repo.insert
                |> case do
                    {:ok, changeset} -> 
                        {:cont, [changeset | acc]}

                    {:error, error} -> 
                        {:halt, {:error, "#{Map.get(item, "name")} already exists in checklists."}}
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

    '''
        Maintenance Alerts
    '''

    def add_alerts_to_maintenance(_maintenance_id, []), do: {:ok, :done}
    def add_alerts_to_maintenance(%{id: id} = maintenance, alerts) do
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
end