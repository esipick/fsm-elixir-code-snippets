defmodule FlightWeb.API.AppointmentControllerTest do
  use FlightWeb.ConnCase, async: false

  alias FlightWeb.API.AppointmentView
  alias Flight.Scheduling.{Availability, Appointment}

  describe "GET /api/appointments/availability" do
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
        |> get("/api/appointments/availability", %{
          start_at: NaiveDateTime.to_iso8601(start_at),
          end_at: NaiveDateTime.to_iso8601(end_at)
        })
        |> json_response(200)

      students_available = Availability.student_availability(start_at, end_at, [], student)
      instructors_available = Availability.instructor_availability(start_at, end_at, [], student)
      aircrafts_available = Availability.aircraft_availability(start_at, end_at, [], student)

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

  describe "GET /api/appointments" do
    test "renders appointments within time range", %{conn: conn} do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2018-03-03 10:00:00], end_at: ~N[2018-03-03 11:00:00]})

      from = NaiveDateTime.to_iso8601(~N[2018-03-03 09:00:00])
      to = NaiveDateTime.to_iso8601(~N[2018-03-03 12:00:00])

      json =
        conn
        |> auth(user_fixture())
        |> get("/api/appointments", %{
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
  end

  describe "GET /api/appointments/:id" do
    @tag :wip
    test "renders appointment", %{conn: conn} do
      appointment =
        appointment_fixture(%{start_at: ~N[2018-03-03 10:00:00], end_at: ~N[2018-03-03 11:00:00]})
        |> FlightWeb.API.AppointmentView.preload()
        |> Flight.Scheduling.apply_timezone(default_school_fixture().timezone)

      json =
        conn
        |> auth(user_fixture())
        |> get("/api/appointments/#{appointment.id}")
        |> json_response(200)

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)
    end
  end

  describe "PUT /api/appointments/:id" do
    @default_date ~N[2018-03-03 10:00:00]
    @default_attrs %{
      start_at: Timex.shift(@default_date, hours: 2),
      end_at: Timex.shift(@default_date, hours: 4)
    }

    test "student updates appointment", %{conn: conn} do
      student = student_fixture()
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()

      school = default_school_fixture()

      appointment =
        appointment_fixture(
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id
          })
        )

      params = %{
        data: %{
          start_at: Timex.shift(@default_date, hours: 3),
          note: "Heyo Timeo"
        }
      }

      json =
        conn
        |> auth(student)
        |> put("/api/appointments/#{appointment.id}", params)
        |> json_response(200)

      assert appointment =
               Flight.Repo.get_by(
                 Appointment,
                 id: appointment.id,
                 start_at:
                   Timex.shift(@default_date, hours: 3)
                   |> Flight.Walltime.utc_to_walltime(school.timezone),
                 note: "Heyo Timeo"
               )
               |> FlightWeb.API.AppointmentView.preload()

      appointment =
        appointment.id
        |> Flight.Scheduling.get_appointment(school)
        |> FlightWeb.API.AppointmentView.preload()

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)
    end
  end

  describe "POST /api/appointments" do
    @default_date ~N[2018-03-03 10:00:00]
    @default_attrs %{
      start_at: Timex.shift(@default_date, hours: 2),
      end_at: Timex.shift(@default_date, hours: 4)
    }

    test "student creates appointment", %{conn: conn} do
      student = student_fixture()
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id
          })
      }

      json =
        conn
        |> auth(student)
        |> post("/api/appointments", params)
        |> json_response(200)

      assert appointment =
               Flight.Repo.get_by(
                 Appointment,
                 user_id: student.id,
                 instructor_user_id: instructor.id,
                 aircraft_id: aircraft.id
               )
               |> Flight.Scheduling.apply_timezone(default_school_fixture().timezone)

      appointment = FlightWeb.API.AppointmentView.preload(appointment)

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)
    end

    test "instructor create appointment", %{conn: conn} do
      student = student_fixture()
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id
          })
      }

      json =
        conn
        |> auth(instructor)
        |> post("/api/appointments", params)
        |> json_response(200)

      assert appointment =
               Flight.Repo.get_by(
                 Appointment,
                 user_id: student.id,
                 instructor_user_id: instructor.id,
                 aircraft_id: aircraft.id
               )
               |> Flight.Scheduling.apply_timezone(default_school_fixture().timezone)

      appointment = FlightWeb.API.AppointmentView.preload(appointment)

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)
    end

    test "can't create appointment without instructor or aircraft", %{conn: conn} do
      student = student_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: student.id
          })
      }

      conn
      |> auth(student)
      |> post("/api/appointments", params)
      |> json_response(400)
    end

    test "student can't create appointment as instructor", %{conn: conn} do
      student = student_fixture()
      _instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: student.id,
            aircraft_id: aircraft.id
          })
      }

      conn
      |> auth(student)
      |> post("/api/appointments", params)
      |> json_response(400)
    end

    test "instructor can't create appointment as student", %{conn: conn} do
      _student = student_fixture()
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: instructor.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id
          })
      }

      conn
      |> auth(instructor)
      |> post("/api/appointments", params)
      |> json_response(400)
    end

    test "student can't create appointment for other student", %{conn: conn} do
      student = student_fixture()
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: student_fixture().id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id
          })
      }

      conn
      |> auth(student)
      |> post("/api/appointments", params)
      |> json_response(400)
    end
  end

  describe "DELETE /api/appointments/:id" do
    test "deletes appointment", %{conn: conn} do
      appointment = appointment_fixture()

      conn
      |> auth(appointment.user)
      |> delete("/api/appointments/#{appointment.id}")
      |> response(204)

      refute Flight.Repo.get(Appointment, appointment.id)
    end
  end
end
