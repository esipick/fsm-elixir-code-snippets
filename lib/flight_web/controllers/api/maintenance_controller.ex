defmodule FlightWeb.API.MaintenanceController do
    use FlightWeb, :controller

    alias Flight.Ecto.Errors
    alias Flight.Inspections

    def create(conn, %{"checklist_ids" => checklist_ids, "aircraft_hours" => aircraft_hours} = params) do
        alerts = Map.get(params, "alerts") || []

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

    def get(conn, params) do
      # get by 
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
end