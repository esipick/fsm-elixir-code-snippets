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

    test "returns availabilities to superadmin", %{conn: conn} do
      _instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      _aircraft = aircraft_fixture()

      date = ~N[2018-03-03 10:30:00]

      start_at = date

      end_at = Timex.shift(date, hours: 2)

      json =
        conn
        |> auth(superadmin_fixture())
        |> get("/api/appointments/availability", %{
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

  describe "GET /api/appointments" do
    test "renders appointments within time range", %{conn: conn} do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2018-03-03 10:00:00], end_at: ~N[2018-03-03 11:00:00]})

      from = NaiveDateTime.to_iso8601(~N[2018-03-03 09:00:00])
      to = NaiveDateTime.to_iso8601(~N[2018-03-03 12:00:00])

      json =
        conn
        |> auth(instructor_fixture())
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

    test "renders appointments with status", %{conn: conn} do
      student = student_fixture()

      appointment1 =
        appointment_fixture(
          %{status: :pending, start_at: ~N[2018-03-03 10:00:00], end_at: ~N[2018-03-03 11:00:00]},
          student
        )

      _appointment2 =
        appointment_fixture(
          %{status: :paid, start_at: ~N[2018-03-03 10:00:00], end_at: ~N[2018-03-03 11:00:00]},
          student
        )

      from = NaiveDateTime.to_iso8601(~N[2018-03-03 09:00:00])
      to = NaiveDateTime.to_iso8601(~N[2018-03-03 12:00:00])

      json =
        conn
        |> auth(student)
        |> get("/api/appointments?status=0", %{
          from: from,
          to: to
        })
        |> json_response(200)

      rendered_data =
        Flight.Scheduling.get_appointments(
          %{"user_id" => student.id, "status" => 0},
          appointment1
        )
        |> FlightWeb.API.AppointmentView.preload()

      assert json == render_json(AppointmentView, "index.json", appointments: rendered_data)
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

    test "superadmin creates appointments", %{conn: conn} do
      school = school_fixture()
      student = student_fixture(%{}, school)
      instructor = user_fixture(%{}, school) |> assign_role("instructor")
      aircraft = aircraft_fixture(%{}, school)
      type = "lesson"

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id,
            type: type
          })
      }

      conn =
        conn
        |> auth(superadmin_fixture())

      conn
      |> post("/api/appointments", params)
      |> json_response(400)

      json =
        conn
        |> post("/api/appointments?school_id=#{school.id}", params)
        |> json_response(200)

      assert appointment =
               Flight.Repo.get_by(
                 Appointment,
                 user_id: student.id,
                 instructor_user_id: instructor.id,
                 aircraft_id: aircraft.id,
                 type: type
               )
               |> Flight.Scheduling.apply_timezone(default_school_fixture().timezone)

      appointment = FlightWeb.API.AppointmentView.preload(appointment)

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)
    end

    test "student creates appointment", %{conn: conn} do
      student = student_fixture()
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()
      type = "lesson"

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id,
            type: type
          })
      }

      conn =
        conn
        |> auth(student)

      json =
        conn
        |> post("/api/appointments", params)
        |> json_response(200)

      assert appointment =
               Flight.Repo.get_by(
                 Appointment,
                 user_id: student.id,
                 instructor_user_id: instructor.id,
                 aircraft_id: aircraft.id,
                 type: type
               )
               |> Flight.Scheduling.apply_timezone(default_school_fixture().timezone)

      appointment = FlightWeb.API.AppointmentView.preload(appointment)

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)

      json =
        conn
        |> post("/api/appointments", params)
        |> json_response(400)

      assert json == %{
               "human_errors" => [
                 "Renter or student has already an appointment at this time",
                 "Instructor is unavailable",
                 "Aircraft is unavailable"
               ]
             }
    end

    test "instructor creates appointment", %{conn: conn} do
      student = student_fixture()
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()
      type = "lesson"

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id,
            type: type
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
                 aircraft_id: aircraft.id,
                 type: type
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
    test "student can't delete paid or ended appointment", %{conn: conn} do
      appointment = appointment_fixture()

      conn
      |> auth(appointment.user)
      |> delete("/api/appointments/#{appointment.id}")
      |> response(401)

      appointment = Flight.Repo.get(Appointment, appointment.id)
      refute appointment.archived

      appointment = appointment_fixture()
      Appointment.paid(appointment)

      conn
      |> auth(appointment.user)
      |> delete("/api/appointments/#{appointment.id}")
      |> response(401)

      appointment = Flight.Repo.get(Appointment, appointment.id)
      refute appointment.archived
    end

    test "student can delete new unpaid appointment", %{conn: conn} do
      today = NaiveDateTime.utc_now()
      start_at = NaiveDateTime.add(today, 50)
      end_at = NaiveDateTime.add(today, 100)
      appointment = appointment_fixture(%{end_at: end_at, start_at: start_at})

      conn
      |> auth(appointment.user)
      |> delete("/api/appointments/#{appointment.id}")
      |> response(204)

      appointment = Flight.Repo.get(Appointment, appointment.id)
      assert appointment.archived
    end

    test "deletes appointment", %{conn: conn} do
      appointment = appointment_fixture()

      conn
      |> auth(appointment.instructor_user)
      |> delete("/api/appointments/#{appointment.id}")
      |> response(204)

      appointment = Flight.Repo.get(Appointment, appointment.id)

      assert appointment.archived
    end
  end
end
