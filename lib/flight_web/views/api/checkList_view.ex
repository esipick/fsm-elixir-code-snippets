defmodule FlightWeb.API.CheckListView do
    use FlightWeb, :view
  
    def render("show.json", %{checklists: checklist}) when is_map(checklist) do
        Map.take(checklist, [:id, :school_id, :name, :description, :created_at, :updated_at])
    end

    def render("show.json", %{checklists: checklist}) when is_list(checklist) do 
        %{result: Enum.map(checklist, &(render("show.json", %{checklists: &1})))}
    end

    def render("show.json", _checklist), do: nil
    
    def render("create.json", _checklists) do
    
    end
end
  