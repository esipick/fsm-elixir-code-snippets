defmodule FlightWeb.API.MaintenanceController do
    use FlightWeb, :controller

    alias Flight.Ecto.Errors
    alias Flight.Inspections
    alias Flight.Squawks
    alias Flight.Scheduling

    def create(%{assigns: %{current_user: %{id: id, school_id: school_id}}} = conn, 
      %{"checklist_ids" => checklist_ids, "aircraft_hours" => aircraft_hours} = params) do
        alerts = Map.get(params, "alerts") || []
        alerts = Enum.map(alerts, &(Map.put(&1, "school_id", school_id)))

        params = 
          params
          |> Map.put("school_id", school_id)
          |> Map.put("creator_id", id)

        with {:ok, _changeset} <- Inspections.create_and_schedule_maintenance(aircraft_hours, checklist_ids, alerts, params) do
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
  
    def assign_aircrafts(conn, %{"maintenance_id" => m_id, "aircraft_hours" => aircrafts}) do
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

      with {:ok, item} <- Inspections.get_maintenance_assoc(maintenance_id) do
        json(conn, %{"result" => item})

      else
        {:error, error} -> 
            json(conn, %{human_errors: [error]})
      end
    end

    def details(%{assigns: %{current_user: %{school_id: school_id}}} = conn, 
      %{"id" => m_id, "aircraft_id" => aircraft_id}) do
    
      with {:ok, maintenance} <- Inspections.get_maintenance_details(m_id, aircraft_id, school_id) do
        json(conn, %{"result" => maintenance})

      else
        {:error, error} ->
          json(conn, %{human_errors: [error]})
      end
    end

    def aircraft_maintenance(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"id" => aircraft_id} = params) do
      {sort_field, sort_order} = sort_params_from_params(params)
      filter =
        %{school_id: school_id}
        # |> filter_from_params
        # |> Map.put(:school_id, school_id)

      with {:ok, maintenance} <- Inspections.get_aircraft_maintenance(aircraft_id, sort_field, sort_order, filter) do
        json(conn, %{"result" => maintenance})
      
      else
        {:error, error} -> json(conn, %{human_errors: [error]})
      end
    end

    def delete(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"id" => id}) do
      with {:ok, _changeset} <- Inspections.delete_maintenance(id, school_id) do
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

    def create_aircraft_maintenance_attachment(conn, %{"aircraft_maintenance_id" => am_id, "items" => items}) do
      with {:ok, _attachments} <- Inspections.upload_aircraft_maintenance_attachments(am_id, items) do
        json(conn, %{"result" => "success"})

      else
        {:error, changeset} ->
            error = Errors.traverse(changeset) 
            json(conn, %{human_errors: [error]})
      end
    end

    def delete_aircraft_maintenance_attachment(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"id" => id}) do
      with {:ok, _} <- Inspections.delete_aircraft_maintenance_attachment(id, school_id) do
        json(conn, %{"result" => "success"})

      else
        {:error, changeset} ->
            error = Errors.traverse(changeset) 
            json(conn, %{human_errors: [error]})
      end
    end

    @doc "Squawks"
    def create_squawk(%{assigns: %{
      current_user: %{school_id: school_id, id: user_id}}} = conn, attrs) do
        aircraft_id = Map.get(attrs, "aircraft_id")
        attrs =
            attrs
            |> Map.put("created_by_id", user_id)
            |> Map.put("school_id", school_id)

        resp = 
          with true <- aircraft_id != nil,
            %{id: _} <- Scheduling.get_aircraft(aircraft_id, conn),
            {:ok, _} <- Squawks.create_squawk_and_notify(attrs) do
              %{"result" => "success"}

          else
            false -> %{human_error: "Aircraft with id is required"}
            nil -> %{human_error: "Aircraft with id: #{aircraft_id} doesn't exists."}
            {:error, changeset} ->
              error = Errors.traverse(changeset) 
              %{"human_errors" => [error]}
          end

        json(conn, resp)
    end

    def get_squawks(%{assigns: %{current_user: %{school_id: school_id}}} = conn, params) do
      page = Map.get(params, "page")
      per_page = Map.get(params, "per_page")
      {sort_field, sort_order} = sort_params_from_params(params)
      filter =
        params
        |> filter_from_params
        |> Map.put(:school_id, school_id)

      squawks = Squawks.get_all_squawks(page, per_page, sort_field, sort_order, filter)
      json(conn, %{"result" => squawks})
    end

    def get_squawk(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"id" => id}) do
      
      with {:ok, squawk} <- Squawks.get_squawk(id, school_id) do
        json(conn, %{"result" => squawk})

      else
        {:error, error} -> json(conn, %{"human_errors" => [error]})
      end
    end

    def delete_squawk_attachment(%{assigns: %{current_user: %{school_id: school_id}}} = conn, %{"id" => id, "squawk_id" => squawk_id}) do
      with {:ok, attachment} <- Squawks.delete_squawk_attachment(id, squawk_id, school_id) do
        json(conn, %{"result" => attachment})

      else
        {:error, error} -> 
          error = Errors.traverse(error) 
          json(conn, %{"human_errors" => [error]})
      end
    end
    def delete_squawk_attachment(conn, _), do: json(conn, %{"human_errors" => ["squawk id required."]})

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
              Map.put(filter, :status, value)

          String.downcase(key) == "urgency" -> #can only be applied when status is pending, [extream, high, normal, low, lowest]
              Map.put(filter, :urgency, value)

          String.downcase(key) == "occurance" -> # can be any_time, past_week, past_month, past_year, current_week, current_month, current_year. "2001-01-01-2002-07-01"
            Map.put(filter, :occurance, value)  

          String.downcase(key) == "aircraft_name" ->
            Map.put(filter, :aircraft_name, value)  
          
          String.downcase(key) == "aircraft_id" ->
              Map.put(filter, :aircraft_id, value)
          
          String.downcase(key) == "name" ->
            Map.put(filter, :name, value)

          String.downcase(key) == "search_term" ->
              Map.put(filter, :search_term, value)
              
          true -> filter
        end 
      end)
    end
end