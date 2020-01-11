defmodule FlightWeb.API.V2.AppointmentControllerTest do
  use FlightWeb.ConnCase, async: false

  alias FlightWeb.API.AppointmentView
  alias Flight.Scheduling.{Availability, Appointment}

  describe "GET /api/v2/appointments/availability" do
    test "returns availabilities", %{conn: conn} do
      _instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      _aircraft = aircraft_fixture()

      date = ~N[2018-03-03 10:30:00]

      start_at = date

      end_at = Timex.shift(date, hours: 2)

      json =
        conn
        |> auth(student)
        |> get("/api/v2/appointments/availability", %{
          start_at: NaiveDateTime.to_iso8601(start_at),
          end_at: NaiveDateTime.to_iso8601(end_at)
        })
        |> json_response(200)

      students_available = Availability.student_availability(start_at, end_at, [], [], student)

      instructors_available =
        Availability.instructor_availability(start_at, end_at, [], [], student)

      aircrafts_available = Availability.aircraft_availability(start_at, end_at, [], [], student)

      assert json ==
               render_json(
                 AppointmentView,
                 "availability.json",
                 students_available: students_available,
                 instructors_available: instructors_available,
                 aircrafts_available: aircrafts_available
               )
    end
  end

  describe "GET /api/v2/appointments" do
    test "renders appointments within time range", %{conn: conn} do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2018-03-03 10:00:00], end_at: ~N[2018-03-03 11:00:00]})

      from = NaiveDateTime.to_iso8601(~N[2018-03-03 09:00:00])
      to = NaiveDateTime.to_iso8601(~N[2018-03-03 12:00:00])

      json =
        conn
        |> auth(instructor_fixture())
        |> get("/api/v2/appointments", %{
          from: from,
          to: to
        })
        |> json_response(200)

      appointment =
        Flight.Scheduling.get_appointments(%{"from" => from, "to" => to}, appointment1)
        |> List.first()
        |> FlightWeb.API.AppointmentView.preload()

      assert json == render_json(AppointmentView, "index.json", appointments: [appointment])
    end

    test "renders appointments within student scope", %{conn: conn} do
      student = student_fixture()
      another_student = student_fixture()
      attrs = %{start_at: ~N[2018-03-03 10:00:00], end_at: ~N[2018-03-03 11:00:00]}

      appointment1 = appointment_fixture(attrs, student)
      _appointment2 = appointment_fixture(attrs, another_student)

      from = NaiveDateTime.to_iso8601(~N[2018-03-03 09:00:00])
      to = NaiveDateTime.to_iso8601(~N[2018-03-03 12:00:00])

      json =
        conn
        |> auth(student)
        |> get("/api/v2/appointments", %{
          from: from,
          to: to
        })
        |> json_response(200)

      rendered_data =
        Flight.Scheduling.get_appointments(%{"user_id" => student.id}, appointment1)
        |> FlightWeb.API.AppointmentView.preload()

      assert json == render_json(AppointmentView, "index.json", appointments: rendered_data)
    end
  end
end
