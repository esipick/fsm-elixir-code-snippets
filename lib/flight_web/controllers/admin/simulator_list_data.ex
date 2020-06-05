defmodule FlightWeb.Admin.SimulatorTableData do
  defstruct [:rows, :page]
end

defmodule FlightWeb.Admin.SimulatorListData do
  defstruct [:table_data, :search_term]

  alias FlightWeb.Admin.SimulatorListData

  def build(school_context, page_params, search_term) do
    page = simulators_page(school_context, page_params, search_term)

    %SimulatorListData{
      search_term: search_term,
      table_data: %FlightWeb.Admin.SimulatorTableData{
        rows: page.entries,
        page: page
      }
    }
  end

  def simulators_page(school_context, page_params, search_term) do
    Flight.Scheduling.visible_simulator_query(school_context, search_term)
    |> Flight.Repo.paginate(page_params)
  end
end
