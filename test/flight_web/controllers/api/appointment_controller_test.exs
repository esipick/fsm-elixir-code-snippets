defmodule FlightWeb.API.AppointmentControllerTest do
  use FlightWeb.ConnCase, async: false

  alias FlightWeb.API.AppointmentView
  alias Flight.Scheduling.{Availability, Appointment}
  alias Flight.Repo
  alias Flight.Billing.Invoice

  describe "GET /api/appointments/availability" do
    test "returns availabilities", %{conn: conn} do
      _instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      _aircraft = aircraft_fixture()

      start_at = ~N[2038-03-03 10:30:00]
      end_at = Timex.shift(start_at, hours: 2)

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

      date = ~N[2038-03-03 10:30:00]

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
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})

      from = NaiveDateTime.to_iso8601(~N[2038-03-03 09:00:00])
      to = NaiveDateTime.to_iso8601(~N[2038-03-03 12:00:00])

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
          %{status: :pending, start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]},
          student
        )

      _appointment2 =
        appointment_fixture(
          %{status: :paid, start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]},
          student
        )

      from = NaiveDateTime.to_iso8601(~N[2038-03-03 09:00:00])
      to = NaiveDateTime.to_iso8601(~N[2038-03-03 12:00:00])

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
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})
        |> FlightWeb.API.AppointmentView.preload()

      json =
        conn
        |> auth(user_fixture())
        |> get("/api/appointments/#{appointment.id}")
        |> json_response(200)

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)
    end
  end

  describe "PUT /api/appointments/:id" do
    @default_date ~N[2038-03-03 10:00:00]
    @default_attrs %{
      start_at: Timex.shift(@default_date, hours: 2),
      end_at: Timex.shift(@default_date, hours: 4)
    }

#    test "student can't assign another student to appointment", %{conn: conn} do
#      student = student_fixture()
#      another_student = student_fixture()
#      appointment = appointment_fixture(%{user_id: student.id})
#      params = %{data: %{user_id: another_student.id}}
#
#      json =
#        conn
#        |> auth(student)
#        |> put("/api/appointments/#{appointment.id}", params)
#        |> json_response(401)
#
#      assert json == %{
#               "human_errors" => [
#                 "You are not authorized to create or change this appointment. Please talk to your school's Admin."
#               ]
#             }
#
#      appointment = appointment_fixture(%{user_id: another_student.id})
#      params = %{data: %{user_id: student.id}}
#
#      json =
#        conn
#        |> auth(student)
#        |> put("/api/appointments/#{appointment.id}", params)
#        |> json_response(401)
#
#      assert json == %{
#               "human_errors" => [
#                 "You are not authorized to create or change this appointment. Please talk to your school's Admin."
#               ]
#             }
#    end

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
               Repo.get_by(
                 Appointment,
                 id: appointment.id,
                 start_at:
                   Timex.shift(@default_date, hours: 3)
                   |> Flight.Walltime.walltime_to_utc(school.timezone),
                 note: "Heyo Timeo"
               )
               |> FlightWeb.API.AppointmentView.preload()

      appointment =
        appointment.id
        |> Flight.Scheduling.get_appointment(school)
        |> FlightWeb.API.AppointmentView.preload()

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)
    end

    test "invoice is updated when appointment is updated", %{conn: conn} do
      student = student_fixture()
      admin = admin_fixture()
      instructor = instructor_fixture(%{billing_rate: 100})
      another_instructor = instructor_fixture(%{billing_rate: 50})
      aircraft = aircraft_fixture(%{rate_per_hour: 100, block_rate_per_hour: 100})
      another_aircraft = aircraft_fixture(%{rate_per_hour: 50, block_rate_per_hour: 50})

      school_context = %Plug.Conn{assigns: %{current_user: admin}}

      appointment =
        appointment_fixture(
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id
          })
        )

      {:ok, invoice} =
        Flight.Billing.CreateInvoiceFromAppointment.run(
          appointment.id,
          %{"payment_option" => "check"},
          school_context
        )

      instructor_item = Enum.find(invoice.line_items, fn i -> i.type == :instructor end)
      aircraft_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)

      assert instructor_item.instructor_user_id == instructor.id
      assert aircraft_item.aircraft_id == aircraft.id
      assert invoice.total_amount_due == 420
      assert invoice.payment_option == :check

      Invoice.changeset(invoice, %{appointment_updated_at: nil}) |> Repo.update()

      params = %{
        data: %{
          start_at: Timex.shift(@default_date, hours: 3),
          note: "Heyo Timeo",
          instructor_user_id: another_instructor.id,
          aircraft_id: another_aircraft.id
        }
      }

      conn
      |> auth(admin)
      |> put("/api/appointments/#{appointment.id}", params)
      |> json_response(200)

      invoice =
        Repo.get(Invoice, invoice.id)
        |> Repo.preload([:line_items, :appointment], force: true)

      instructor_item = Enum.find(invoice.line_items, fn i -> i.type == :instructor end)
      aircraft_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)

      assert instructor_item.instructor_user_id == another_instructor.id
      assert aircraft_item.aircraft_id == another_aircraft.id
      assert invoice.total_amount_due == 155
      assert invoice.payment_option == :check
    end

    test "student updates appointment for the same time", %{conn: conn} do
      student = student_fixture()
      instructor = user_fixture() |> assign_role("instructor")
      aircraft = aircraft_fixture()

      appointment =
        appointment_fixture(
          @default_attrs
          |> Map.merge(%{
            user_id: student.id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft.id
          })
        )

      params = %{data: %{note: "Heyo Timeo"}}

      conn
      |> auth(student)
      |> put("/api/appointments/#{appointment.id}", params)
      |> json_response(200)
    end

    @tag :integration
    test "show error if appointment already removed", %{conn: conn} do
      appointment = appointment_fixture()

      Appointment.archive(appointment)

      params = %{
        data: %{note: "Heyo Timeo"}
      }

      json =
        conn
        |> auth(appointment.instructor_user)
        |> put("/api/appointments/#{appointment.id}", params)
        |> json_response(401)

      assert json == %{
               "human_errors" => [
                 "Appointment already removed please recreate it"
               ]
             }
    end
  end

  describe "POST /api/appointments" do
    @default_date ~N[2038-03-03 10:00:00]
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
               Repo.get_by(
                 Appointment,
                 user_id: student.id,
                 instructor_user_id: instructor.id,
                 aircraft_id: aircraft.id,
                 type: type
               )

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
               Repo.get_by(
                 Appointment,
                 user_id: student.id,
                 instructor_user_id: instructor.id,
                 aircraft_id: aircraft.id,
                 type: type
               )

      appointment = FlightWeb.API.AppointmentView.preload(appointment)

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)

      json =
        conn
        |> post("/api/appointments", params)
        |> json_response(400)

      assert json == %{
               "human_errors" => [
                 "The renter/student already has an appointment at this time.",
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
               Repo.get_by(
                 Appointment,
                 user_id: student.id,
                 instructor_user_id: instructor.id,
                 aircraft_id: aircraft.id,
                 type: type
               )

      appointment = FlightWeb.API.AppointmentView.preload(appointment)

      assert json == render_json(AppointmentView, "show.json", appointment: appointment)
    end

    test "instructor creates appointment for themselves", %{conn: conn} do
      instructor = user_fixture() |> assign_role("instructor")

      params = %{
        data:
          @default_attrs
          |> Map.merge(%{instructor_user_id: instructor.id})
      }

      json =
        conn
        |> auth(instructor)
        |> post("/api/appointments", params)
        |> json_response(200)

      appointment =
        Repo.get(Appointment, json["data"]["id"])
        |> FlightWeb.API.AppointmentView.preload()

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
      |> json_response(401)
    end
  end

  describe "DELETE /api/appointments/:id" do
    test "student can't delete paid appointment", %{conn: conn} do
      appointment = appointment_fixture()
      Appointment.paid(appointment)

      conn
      |> auth(appointment.user)
      |> delete("/api/appointments/#{appointment.id}")
      |> response(401)

      appointment = Repo.get(Appointment, appointment.id)
      refute appointment.archived
    end

    test "dispatcher can delete paid", %{conn: conn} do
      appointment = appointment_fixture()
      Appointment.paid(appointment)

      conn
      |> auth(dispatcher_fixture())
      |> delete("/api/appointments/#{appointment.id}")
      |> response(204)

      appointment = Repo.get(Appointment, appointment.id)
      assert appointment.archived
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

      appointment = Repo.get(Appointment, appointment.id)
      assert appointment.archived
    end

    test "instructor can't delete other user appointment", %{conn: conn} do
      instructor_user = instructor_fixture()
      appointment = appointment_fixture()

      conn
      |> auth(instructor_user)
      |> delete("/api/appointments/#{appointment.id}")
      |> response(401)

      appointment = Repo.get(Appointment, appointment.id)
      refute appointment.archived
    end

    test "instructor can delete own appointment", %{conn: conn} do
      appointment = appointment_fixture()

      conn
      |> auth(appointment.instructor_user)
      |> delete("/api/appointments/#{appointment.id}")
      |> response(204)

      appointment = Repo.get(Appointment, appointment.id)
      assert appointment.archived
    end

    @tag :integration
    test "show error if appointment already removed", %{conn: conn} do
      appointment = appointment_fixture()

      Appointment.archive(appointment)

      json =
        conn
        |> auth(appointment.instructor_user)
        |> delete("/api/appointments/#{appointment.id}")
        |> json_response(401)

      assert json == %{
               "human_errors" => [
                 "Appointment already removed please recreate it"
               ]
             }
    end
  end
end
