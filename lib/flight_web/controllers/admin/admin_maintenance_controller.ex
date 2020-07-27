defmodule FlightWeb.Admin.MaintenanceController do
    use FlightWeb, :controller

    def index(conn, _params) do
        # render a page here.
    end

    def create(conn, %{"checklist_ids" => checklist_ids, "aircraft_hours" => aircraft_hours} = params) do
        # call create method in logic
        # redirect page
        with {:ok, changeset} <- Inspections.create_and_schedule_maintenance(aircraft_hours, checklist_ids, params) do
            # redirect instead
            json(conn, %{"result" => "success"})
          else
            {:error, error} ->
                #redirect and flush instead
              error = Errors.traverse(error) 
              IO.inspect(error)
              json(conn, %{human_errors: [error]})
          end
    end
end