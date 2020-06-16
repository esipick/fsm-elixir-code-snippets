defmodule FlightWeb.API.AppointmentView do
  use FlightWeb, :view

  def render("availability.json", %{
        students_available: students_available,
        instructors_available: instructors_available,
        aircrafts_available: aircrafts_available
      }) do
    %{
      data: %{
        students:
          render_many(
            students_available,
            FlightWeb.API.AppointmentView,
            "availability_user.json",
            as: :availability_user
          ),
        instructors:
          render_many(
            instructors_available,
            FlightWeb.API.AppointmentView,
            "availability_user.json",
            as: :availability_user
          ),
        aircrafts:
          render_many(
            aircrafts_available,
            FlightWeb.API.AppointmentView,
            "availability_aircraft.json",
            as: :availability_aircraft
          )
      }
    }
  end

  def render("availability_user.json", %{availability_user: user}) do
    %{
      user: %{
        id: user.user.id,
        first_name: user.user.first_name,
        last_name: user.user.last_name
      },
      status: user.status
    }
  end

  def render("availability_aircraft.json", %{availability_aircraft: aircraft}) do
    %{
      aircraft: render(FlightWeb.API.AircraftView, "aircraft.json", aircraft: aircraft.aircraft),
      status: aircraft.status
    }
  end

  def render("show.json", %{appointment: appointment}) do
    %{
      data: render("appointment.json", appointment: appointment)
    }
  end

  def render("index.json", %{appointments: appointments}) do
    %{
      data:
        render_many(
          appointments,
          FlightWeb.API.AppointmentView,
          "appointment.json",
          as: :appointment
        )
    }
  end

  def render("appointment.json", %{appointment: appointment}) do
    school = Flight.Accounts.get_school(appointment.school_id)
    timezone = school.timezone

    %{
      id: appointment.id,
      start_at: Flight.NaiveDateTime.to_walltime_json(appointment.start_at, timezone),
      end_at: Flight.NaiveDateTime.to_walltime_json(appointment.end_at, timezone),
      user:
        Optional.map(
          appointment.user,
          &render(FlightWeb.API.UserView, "skinny_user.json", user: &1)
        ),
      transaction_id: appointment.transaction_id,
      note: appointment.note,
      status: appointment.status,
      instructor_user:
        Optional.map(
          appointment.instructor_user,
          &render(FlightWeb.API.UserView, "skinny_user.json", user: &1)
        ),
      owner_user_id: appointment.owner_user_id,
      aircraft:
        Optional.map(
          appointment.aircraft,
          &render(FlightWeb.API.AircraftView, "aircraft.json", aircraft: &1)
        )
    }
  end

  def preload(appointments) do
    Flight.Repo.preload(appointments, [:user, :instructor_user, [aircraft: :inspections]])
  end
end
