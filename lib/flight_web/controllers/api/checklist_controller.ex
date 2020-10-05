defmodule FlightWeb.API.CheckListController do
    use FlightWeb, :controller

    alias Flight.Inspections
    alias Flight.Ecto.Errors

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

        checklists = Inspections.get_all_checklists(page, per_page, sort_field, sort_order, filter)
        render(conn, "show.json", checklists: checklists)
    end

    def categories(conn, _params) do
        json(conn, %{"result" => Inspections.get_checklist_categories()})
    end

    def create(conn, %{"_json" => params}), do: create(conn, params)    
    def create(%{assigns: %{current_user: %{school_id: school_id}}} = conn, params) do

        with {:ok, checklists} <- Inspections.create_checklist(school_id, params) do
            render(conn, "show.json", checklists: checklists)

        else
            {:error, error} -> json(conn, %{ human_errors: [error]})
        end
    end

    def delete(conn, %{"id" => id}) do
        with {:ok, _changeset} <- Inspections.delete_checklist(id) do
            json(conn, %{"result" => "success"})
        else
            {:error, changeset} ->
                error = Errors.traverse(changeset) 
                json(conn, %{human_errors: [error]})
        end
    end

    def delete_checklist_from_maintenance(conn, %{"maintenance_id" => m_id, "checklist_ids" => checklist_ids}) do
        {:ok, :done} = Inspections.delete_checklist_from_maintenance(m_id, checklist_ids)

        json(conn, %{"result" => "success"})
    end
end