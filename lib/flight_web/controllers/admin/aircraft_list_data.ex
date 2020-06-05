defmodule FlightWeb.Admin.AircraftTableData do
  defstruct [:rows, :page]
end

defmodule FlightWeb.Admin.AircraftListData do
  defstruct [:table_data, :search_term]

  alias FlightWeb.Admin.AircraftListData

  def build(school_context, page_params, search_term \\ "") do
    page = aircrafts_page(school_context, page_params, search_term)

    %AircraftListData{
      search_term: search_term,
      table_data: %FlightWeb.Admin.AircraftTableData{
        rows: page.entries,
        page: page
      }
    }
  end

  def aircrafts_page(school_context, page_params, search_term) do
    Flight.Scheduling.visible_aircraft_query(school_context, search_term)
    |> Flight.Repo.paginate(page_params)
  end
end
