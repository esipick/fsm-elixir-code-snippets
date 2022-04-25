defmodule FlightWeb.API.UnavailabilityView do
  use FlightWeb, :view

  def render("show.json", %{unavailability: unavailability}) do
    %{
      data: render("unavailability.json", unavailability: unavailability)
    }
  end

  def render("index.json", %{unavailabilities: unavailabilities}) do
    %{
      data:
        render_many(
          unavailabilities,
          FlightWeb.API.UnavailabilityView,
          "unavailability.json",
          as: :unavailability
        )
    }
  end

  def render("unavailability.json", %{unavailability: unavailability}) do
    %{
      id: unavailability.id,
      start_at: unavailability.start_at, # utc time response
      end_at: unavailability.end_at, # utc time response
      note: unavailability.note,
      type: unavailability.type,
      parent_id: unavailability.parent_id,
      instructor_user:
        Optional.map(
          unavailability.instructor_user,
          &render(FlightWeb.API.UserView, "skinny_user.json", user: &1)
        ),
      aircraft:
        Optional.map(
          unavailability.aircraft,
          &render(FlightWeb.API.AircraftView, "aircraft.json", aircraft: &1)
        ),
      room:
        Optional.map(
          unavailability.room,
          &render(FlightWeb.API.RoomView, "room.json", room: &1)
        ),
      simulator:
        Optional.map(
          unavailability.simulator,
          &render(FlightWeb.API.AircraftView, "aircraft.json", aircraft: &1)
        )
    }
  end

  def preload(unavailabilities) do
    Flight.Repo.preload(unavailabilities, [:instructor_user, :room, [aircraft: :inspections], [simulator: :inspections]])
  end
end
