defmodule FlightWeb.API.RoomController do
  use FlightWeb, :controller

  alias Flight.Auth.Permission
  alias Flight.SchoolAssets

  plug(:authorize_view_all when action in [:autocomplete])

  def index(conn, _) do
    rooms = SchoolAssets.visible_rooms(conn)
    render(conn, "index.json", rooms: rooms)
  end

  def autocomplete(conn, %{"search" => search_term} = _params) do
    rooms =
      SchoolAssets.visible_room_query(conn, search_term)
      |> Flight.Repo.all()

    render(conn, "autocomplete.json", rooms: rooms)
  end

  def authorize_view_all(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:room, :view, :all)])
  end
end
