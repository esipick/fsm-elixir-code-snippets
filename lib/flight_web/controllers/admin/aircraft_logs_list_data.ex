defmodule FlightWeb.Admin.AircraftLogsTableData do
  defstruct [:rows, :page]
end

defmodule FlightWeb.Admin.AircraftLogsListData do
  defstruct [:table_data, :search_term]

  alias FlightWeb.Admin.AircraftLogsListData

  def build(school_context, page_params, search_term \\ "") do
    page = aircraft_logs_page(school_context, page_params, search_term)

    %AircraftLogsListData{
      search_term: search_term,
      table_data: %FlightWeb.Admin.AircraftLogsTableData{
        rows: page.entries,
        page: page
      }
    }
  end

  def aircraft_logs_page(school_context, page_params, search_term) do
    Flight.Log.visible_aircraft_logs_query(school_context, search_term)
    |> Flight.Repo.paginate(page_params)
  end
end
