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
      aircraft: %{
        id: aircraft.aircraft.id,
        make: aircraft.aircraft.make,
        model: aircraft.aircraft.model
      },
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
    %{
      id: appointment.id,
      start_at: Flight.NaiveDateTime.to_json(appointment.start_at),
      end_at: Flight.NaiveDateTime.to_json(appointment.end_at),
      user: render(FlightWeb.API.UserView, "skinny_user.json", user: appointment.user),
      instructor_user:
        Optional.map(
          appointment.instructor_user,
          &render(FlightWeb.API.UserView, "skinny_user.json", user: &1)
        ),
      aircraft:
        Optional.map(
          appointment.aircraft,
          &render(FlightWeb.API.AircraftView, "aircraft.json", aircraft: &1)
        )
    }
  end
end
