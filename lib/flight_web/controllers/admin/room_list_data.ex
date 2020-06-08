defmodule FlightWeb.Admin.RoomTableData do
  defstruct [:rows, :page]
end

defmodule FlightWeb.Admin.RoomListData do
  defstruct [:table_data]

  alias FlightWeb.Admin.RoomListData

  def build(school_context, page_params) do
    page = rooms_page(school_context, page_params)

    %RoomListData{
      table_data: %FlightWeb.Admin.RoomTableData{
        rows: page.entries,
        page: page
      }
    }
  end

  def rooms_page(school_context, page_params) do
    Flight.SchoolAssets.visible_room_query(school_context)
    |> Flight.Repo.paginate(page_params)
  end
end
