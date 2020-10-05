defmodule FlightWeb.Admin.MaintenanceController do
    use FlightWeb, :controller

    # alias Flight.Ecto.Errors
    # alias Flight.Inspections

    def index(_conn, _params) do
        # render a page here.

        # render("index.html", %{})
    end

    def create(conn, %{"checklist_ids" => _checklist_ids, "aircraft_hours" => _aircraft_hours} = _params) do
        # call create method in logic
        # redirect page
        json(conn, %{"result" => "success"})
        # with {:ok, changeset} <- Inspections.create_and_schedule_maintenance(aircraft_hours, checklist_ids, params) do
        #     # redirect instead
        #     json(conn, %{"result" => "success"})
        #   else
        #     {:error, error} ->
        #         #redirect and flush instead
        #       error = Errors.traverse(error) 
        #       IO.inspect(error)
        #       json(conn, %{human_errors: [error]})
        #   end
    end
end