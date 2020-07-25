defmodule FlightWeb.API.MaintenanceController do
    use FlightWeb, :controller

    alias Flight.Ecto.Errors
    alias Flight.Inspections

    def create(conn, %{"checklist_ids" => checklist_ids, "aircraft_hours" => aircraft_hours} = params) do
        
        with {:ok, changeset} <- Inspections.create_and_schedule_maintenance(aircraft_hours, checklist_ids, params) do
          json(conn, %{"result" => "success"})
        else
          {:error, error} ->
            error = Errors.traverse(error) 
            IO.inspect(error)
            json(conn, %{human_errors: [error]})
        end
    end
end