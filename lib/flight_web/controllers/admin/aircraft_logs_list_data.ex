defmodule FlightWeb.Admin.AircraftLogsTableData do
  defstruct [:rows, :page]
end

defmodule FlightWeb.Admin.AircraftLogsListData do
  defstruct [:table_data, :search_term]

  alias FlightWeb.Admin.AircraftLogsListData
  # alias FlightWeb.Aircraft.AircraftLogStruct

  alias Flight.Repo
  def build(school_context, page_params, search_term \\ "") do
    page = aircraft_logs_page(school_context, page_params, search_term)

    %AircraftLogsListData{
      search_term: search_term,
      table_data: %FlightWeb.Admin.AircraftLogsTableData{
        rows: page,
        page: page
      }
    }
  end

  def aircraft_logs_page(school_context, _page_params, search_term) do
    Flight.Log.visible_aircraft_logs_query(school_context, search_term)
    |> Repo.all
  end
end
