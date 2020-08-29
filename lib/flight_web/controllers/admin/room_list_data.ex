defmodule FlightWeb.Admin.RoomTableData do
  defstruct [:rows, :page]
end

defmodule FlightWeb.Admin.RoomListData do
  defstruct [:table_data, :search_term]

  alias FlightWeb.Admin.RoomListData

  def build(school_context, page_params, search_term \\ "") do
    page = rooms_page(school_context, page_params, search_term)

    %RoomListData{
      search_term: search_term,
      table_data: %FlightWeb.Admin.RoomTableData{
        rows: page.entries,
        page: page
      }
    }
  end

  def rooms_page(school_context, page_params, search_term) do
    Flight.SchoolAssets.visible_room_query(school_context, search_term)
    |> Flight.Repo.paginate(page_params)
  end
end
