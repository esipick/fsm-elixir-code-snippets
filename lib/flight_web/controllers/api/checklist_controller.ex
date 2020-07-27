defmodule FlightWeb.API.CheckListController do
    use FlightWeb, :controller

    alias Flight.Inspections

    def index(conn, params) do
        page = Map.get(params, "page")
        per_page = Map.get(params, "per_page")
        sort_field = 
            (Map.get(params, "sort_field") || "name")
            |> String.to_atom
        
        sort_order = 
            (Map.get(params, "sort_order") || "asc")
            |> String.to_atom
        
        filter = nil

        checklists = Inspections.get_all_checklists(nil, nil, sort_field, sort_order, filter)
        render(conn, "show.json", checklists: checklists)
    end

    def create(conn, %{"_json" => params}), do: create(conn, params)    
    def create(%{assigns: %{current_user: %{school_id: school_id}}} = conn, params) do

        with {:ok, checklists} <- Inspections.create_checklist(school_id, params) do
            render(conn, "show.json", checklists: checklists)

        else
            {:error, error} -> json(conn, %{ human_errors: [error]})
        end
    end
end