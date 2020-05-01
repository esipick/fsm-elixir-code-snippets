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
    school = Flight.Accounts.get_school(unavailability.school_id)
    timezone = school.timezone

    %{
      id: unavailability.id,
      start_at: Flight.NaiveDateTime.to_walltime_json(unavailability.start_at, timezone),
      end_at: Flight.NaiveDateTime.to_walltime_json(unavailability.end_at, timezone),
      note: unavailability.note,
      type: unavailability.type,
      instructor_user:
        Optional.map(
          unavailability.instructor_user,
          &render(FlightWeb.API.UserView, "skinny_user.json", user: &1)
        ),
      aircraft:
        Optional.map(
          unavailability.aircraft,
          &render(FlightWeb.API.AircraftView, "aircraft.json", aircraft: &1)
        )
    }
  end

  def preload(unavailabilities) do
    Flight.Repo.preload(unavailabilities, [:instructor_user, [aircraft: :inspections]])
  end
end
