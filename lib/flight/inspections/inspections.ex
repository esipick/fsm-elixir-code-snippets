defmodule Flight.Inspections do
    alias Flight.Repo

    alias Flight.Accounts
    alias Flight.Inspections.{
        Queries,
        CheckList,
        Maintenance,
        AircraftMaintenance,
        MaintenanceCheckList
    }

    def get_all_maintenance(sort_field, sort_order, filter) do
        {:ok, []}
    end

    def get_maintenance(id) do
        Repo.get(Maintenance, id)
        |> case do
            nil -> {:error, "User Not found"}
            item -> {:ok, item}
        end
    end

    def create_and_schedule_maintenance(_aircraft_ids, [], _params), do: {:error, "No CheckList being added."}
    def create_and_schedule_maintenance([], _checklist_ids, _params), do: {:error, "No Aircraft & hours being assigned."}
    def create_and_schedule_maintenance(aircraft_hours, checklist_ids, params) do
        checklist_ids = MapSet.to_list(MapSet.new(checklist_ids))
        
        Repo.transaction(fn -> 
            with {:ok, %{id: id} = maintenance} <- create_maintenance(params),
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

    def create_checklist(school_id, params) when is_map(params) do
        create_checklist(school_id, [params])
    end

    def create_checklist(school_id, params) do
        school = Accounts.get_school(school_id)
        params = Enum.map(params, fn(item) -> CheckList.changeset(%CheckList{}, Map.put(item, "school_id", school_id)) end)
        valid = Enum.all?(params, &(&1.valid?))

        cond do
            valid && school -> 
                params = Enum.map(params, &(&1.changes))
                Repo.insert_all(CheckList, params, [])
    
                {:ok, "success"}

            !valid -> {:error, "Name cannot be empty or null."}
            true -> {:error, "School with id: #{school_id} not found."}
        end
    end

    defp add_checklists_to_maintenance(maintenance_id, checklist_ids) do
        items = Enum.map(checklist_ids, &(%{maintenance_id: maintenance_id, checklist_id: &1}))
        Repo.insert_all(MaintenanceCheckList, items, on_conflict: :nothing, conflict_target: [:maintenance_id, :checklist_id])

        {:ok, :done}
    end

    defp assign_maintenance_to_aircrafts(maintenance_id, aircraft_hours) do
        items = 
            Enum.map(aircraft_hours, fn(item) -> 
                AircraftMaintenance.changeset(%AircraftMaintenance{}, Map.put(item, "maintenance_id", maintenance_id)) 
            end)
        
        valid = Enum.all?(items, &(&1.valid?))
        
        if valid do
            items = Enum.map(items, &(&1.changes))
            Repo.insert_all(AircraftMaintenance, items, conflict_target: [:aircraft_id, :maintenance_id, :status], on_conflict: :nothing)

            {:ok, :done}

        else
            {:error, items}
        end
    end
end