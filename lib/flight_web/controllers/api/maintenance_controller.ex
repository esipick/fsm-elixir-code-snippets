defmodule FlightWeb.API.MaintenanceController do
    use FlightWeb, :controller

    alias Flight.Ecto.Errors
    alias Flight.Inspections

    def create(%{assigns: %{current_user: %{school_id: school_id}}} = conn, 
      %{"checklist_ids" => checklist_ids, "aircraft_hours" => aircraft_hours} = params) do
        alerts = Map.get(params, "alerts") || []
        alerts = Enum.map(alerts, &(Map.put(&1, "school_id", school_id)))
        params = Map.put(params, "school_id", school_id)

        with {:ok, changeset} <- Inspections.create_and_schedule_maintenance(aircraft_hours, checklist_ids, alerts, params) do
          json(conn, %{"result" => "success"})
        else
          {:error, error} ->
            error = Errors.traverse(error) 
            json(conn, %{human_errors: [error]})
        end
    end

    def add_checklist(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"maintenance_id" => maintenance_id, "checklists" => checklists}) do
      with {:ok, :done} <- Inspections.add_checklists_to_maintenance(school_id, maintenance_id, checklists) do
        json(conn, %{"result" => "success"})
      
      else
        {:error, error} -> json(conn, %{human_errors: [error]})
      end
    end
  
    def assign_aircrafts(conn, %{"maintenance_id" => m_id, "aircrafts" => aircrafts} = params) do
      with  {:ok, :done} <- Inspections.assign_maintenance_to_aircrafts_transaction(m_id, aircrafts) do
        json(conn, %{"result" => "success"})

      else
        {:error, error} -> json(conn, %{human_errors: [error]})
      end
    end

    def get(%{assigns: %{current_user: %{school_id: school_id}}} = conn, params) do
      page = Map.get(params, "page")
      per_page = Map.get(params, "per_page")
      {sort_field, sort_order} = sort_params_from_params(params)
      filter =
        params
        |> filter_from_params
        |> Map.put(:school_id, school_id)

      maintenance = Inspections.get_all_maintenance(page, per_page, sort_field, sort_order, filter)
      json(conn, %{"result" => maintenance})
    end

    def show(conn, %{"id" => maintenance_id}) do
      #
      with {:ok, item} <- Inspections.get_maintenance_assoc(maintenance_id) do
        json(conn, %{"result" => item})

      else
        {:error, error} -> 
            json(conn, %{human_errors: [error]})
      end
    end

    def aircraft_maintenance(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"id" => aircraft_id} = params) do
      {sort_field, sort_order} = sort_params_from_params(params)
      filter =
        params
        |> filter_from_params
        |> Map.put(:school_id, school_id)

      with {:ok, maintenance} <- Inspections.get_aircraft_maintenance(aircraft_id, sort_field, sort_order, filter) do
        json(conn, %{"result" => maintenance})
      
      else
        {:error, error} -> json(conn, %{human_errors: [error]})
      end
    end

    def delete(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"id" => id}) do
      with {:ok, changeset} <- Inspections.delete_maintenance(id, school_id) do
        json(conn, %{"result" => "success"})
        
      else
        {:error, changeset} ->
            error = Errors.traverse(changeset) 
            json(conn, %{human_errors: [error]})
      end
    end

    def remove_aircrafts_from_maintenance(conn, %{"maintenance_id" => m_id, "aircraft_ids" => aircraft_ids}) do
      {:ok, :done} = Inspections.remove_aircrafts_from_maintenance(m_id, aircraft_ids)
      json(conn, %{"result" => "success"})
    end

    defp sort_params_from_params(params) do
      sort_field = 
        (Map.get(params, "sort_field") || "aircraft_name")
        |> String.to_atom
  
      sort_order = 
          (Map.get(params, "sort_order") || "asc")
          |> String.to_atom

      {sort_field, sort_order}
    end

    defp filter_from_params(params) do
      Enum.reduce(params, %{}, fn({key, value}, filter) ->
        
        cond do
          String.downcase(key) =="status" ->
              Integer.parse(value)
              |> case do
                {value, _} -> Map.put(filter, :proximity, value)
                _ -> filter
              end

          String.downcase(key) == "maintenance_name" ->
            Map.put(filter, :maintenance_name, value)  

          String.downcase(key) == "aircraft_name" ->
            Map.put(filter, :aircraft_name, value)  
          
          String.downcase(key) == "aircraft_id" ->
              Map.put(filter, :aircraft_id, value)

          String.downcase(key) == "event_date" ->
            # could be, any_time, past_week, past_month, past_year, upcoming_weak, upcoming_month, upcoming_year
            Map.put(filter, :remaining_days, value)

          String.downcase(key) == "remaining_tach" ->
              Integer.parse(value)
              |> case do
                {value, _} -> Map.put(filter, :remaining_tach, value)
                _ -> filter
              end
          
          String.downcase(key) == "remaining_days" ->
              Map.put(filter, :remaining_days, value)
          true -> filter
        end 
      end)
    end
end