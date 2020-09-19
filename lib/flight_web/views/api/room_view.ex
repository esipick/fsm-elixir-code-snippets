defmodule FlightWeb.API.RoomView do
  use FlightWeb, :view

  alias FlightWeb.API.RoomView

  def render("index.json", %{rooms: rooms}) do
    %{
      data: render_many(rooms, RoomView, "room.json", as: :room)
    }
  end

  def render("room.json", %{room: room}) do
    %{
      id: room.id,
      capacity: room.capacity,
      location: room.location,
      resources: room.resources,
      rate_per_hour: room.rate_per_hour,
      block_rate_per_hour: room.block_rate_per_hour,
      school_id: room.school_id
    }
  end

  def render("autocomplete.json", %{rooms: rooms}) do
    %{data: render_many(rooms, RoomView, "room.json", as: :rooms)}
  end
end
