defmodule Flight.SchedulingTest do
  use Flight.DataCase

  alias Flight.{Repo, Scheduling}
  alias Flight.Scheduling.{Unavailability, Aircraft, Appointment, Inspection}

  import Flight.{AccountsFixtures, Walltime}

  describe "aircrafts" do
    @valid_attrs %{
      make: "make",
      model: "model",
      tail_number: "N876",
      serial_number: "54-58423",
      equipment: "equipment",
      ifr_certified: true,
      simulator: false,
      last_tach_time: 8010,
      last_hobbs_time: 8000,
      rate_per_hour: 130,
      block_rate_per_hour: 120
    }

    test "create_aircraft/1 returns aircraft" do
      assert {:ok, %Aircraft{} = aircraft} =
               Scheduling.admin_create_aircraft(@valid_attrs, default_school_fixture())

      assert aircraft.make == "make"
      assert aircraft.model == "model"
      assert aircraft.tail_number == "N876"
      assert aircraft.serial_number == "54-58423"
      assert aircraft.ifr_certified == true
      assert aircraft.simulator == false
      assert aircraft.last_tach_time == 8010
      assert aircraft.last_hobbs_time == 8000
      assert aircraft.rate_per_hour == 130
      assert aircraft.block_rate_per_hour == 120
      assert aircraft.equipment == "equipment"
    end

    test "create_aircraft/1 creates default inspections" do
      assert {:ok, %Aircraft{} = aircraft} =
               Scheduling.admin_create_aircraft(@valid_attrs, default_school_fixture())

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "Annual",
               type: "date"
             )

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "Transponder",
               type: "date"
             )

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "Altimeter",
               type: "date"
             )

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "ELT",
               type: "date"
             )

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "100hr",
               type: "tach"
             )
    end

    test "create_aircraft/1 returns error" do
      assert {:error, _} = Scheduling.admin_create_aircraft(%{}, default_school_fixture())
    end

    test "get_visible_air_asset/1 gets aircraft" do
      aircraft = aircraft_fixture()

      assert %Aircraft{} = Scheduling.get_visible_air_asset(aircraft.id, aircraft)
    end

    test "visible_air_assets/0 gets aircrafts" do
      aircraft_fixture()
      aircraft_fixture()
      simulator_fixture()

      assert [%Aircraft{}, %Aircraft{}, %Aircraft{}] =
               Scheduling.visible_air_assets(default_school_fixture())
    end

    test "update_aircraft/2 updates" do
      aircraft = aircraft_fixture()

      assert {:ok, %Aircraft{make: "New Model"}} =
               Scheduling.admin_update_aircraft(aircraft, %{make: "New Model"})
    end
  end

  describe "inspections" do
    @valid_attrs %{
      name: "Some New Name",
      aircraft_id: 3,
      expiration: "3/3/2038"
    }

    test "create_date_inspection/1 creates inspection" do
      aircraft = aircraft_fixture()

      {:ok, _inspection} =
        Scheduling.create_date_inspection(%{@valid_attrs | aircraft_id: aircraft.id})

      assert Flight.Repo.get_by(
               Inspection,
               name: "Some New Name",
               aircraft_id: aircraft.id,
               date_value: "3/3/2038"
             )
    end

    test "create_date_inspection/1 fails and returns correct changeset" do
      aircraft = aircraft_fixture()

      {:error, changeset} =
        Scheduling.create_date_inspection(%{
          @valid_attrs
          | expiration: "3/3/201",
            aircraft_id: aircraft.id
        })

      assert Enum.count(errors_on(changeset).expiration) > 0
    end

    test "update_inspection/2 updates date inspection" do
      inspection = date_inspection_fixture()

      {:ok, _inspection} = Scheduling.update_inspection(inspection, %{name: "Somethin' crazy"})

      assert Flight.Repo.get_by(
               Inspection,
               name: "Somethin' crazy"
             )
    end

    test "update_inspection/2 updates tach inspection" do
      inspection = tach_inspection_fixture()

      {:ok, _inspection} = Scheduling.update_inspection(inspection, %{name: "Somethin' crazy"})

      assert Flight.Repo.get_by(
               Inspection,
               name: "Somethin' crazy"
             )
    end

    test "update_inspection/2 update fails date" do
      inspection = date_inspection_fixture()

      {:error, changeset} = Scheduling.update_inspection(inspection, %{name: nil})

      assert Enum.count(errors_on(changeset).name) > 0
    end
  end

  #
  # Appointments
  #

  describe "appointments" do
    def create_appointment(data, school \\ default_school_fixture()) do
      Scheduling.insert_or_update_appointment(
        %Scheduling.Appointment{},
        data,
        admin_fixture(),
        school
      )
    end

    test "insert_or_update_appointment/1 creates appointment" do
      instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      aircraft = aircraft_fixture()
      school = default_school_fixture()

      now = NaiveDateTime.utc_now()
      start_at = NaiveDateTime.truncate(Timex.shift(now, hours: 1), :second)
      end_at = NaiveDateTime.truncate(Timex.shift(now, hours: 2), :second)

      type = "lesson"

      {:ok, %Appointment{} = appointment} =
        create_appointment(
          %{
            start_at: start_at,
            end_at: end_at,
            instructor_user_id: instructor.id,
            user_id: student.id,
            aircraft_id: aircraft.id,
            type: type
          },
          school
        )

      assert appointment.start_at == walltime_to_utc(start_at, student.school.timezone)
      assert appointment.end_at == walltime_to_utc(end_at, student.school.timezone)
      assert appointment.instructor_user_id == instructor.id
      assert appointment.user_id == student.id
      assert appointment.aircraft_id == aircraft.id
      assert appointment.type == type
    end

    @tag :wip
    test "insert_or_update_appointment/1 updates existing appointment" do
      instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      timezone = student.school.timezone
      aircraft = aircraft_fixture()
      type = "lesson"

      now = NaiveDateTime.utc_now()

      start_at =
        NaiveDateTime.truncate(Timex.shift(now, hours: 2), :second)
        |> utc_to_walltime(timezone)

      end_at =
        NaiveDateTime.truncate(Timex.shift(now, hours: 3), :second)
        |> utc_to_walltime(timezone)

      {:ok, %Appointment{} = appointment} =
        create_appointment(%{
          start_at: start_at,
          end_at: end_at,
          instructor_user_id: instructor.id,
          user_id: student.id,
          aircraft_id: aircraft.id,
          type: type
        })

      new_start_at =
        NaiveDateTime.truncate(Timex.shift(now, hours: 2, minutes: 30), :second)
        |> utc_to_walltime(timezone)

      {:ok, %Appointment{} = updatedAppointment} =
        Scheduling.insert_or_update_appointment(
          appointment,
          %{
            start_at: new_start_at
          },
          admin_fixture(),
          default_school_fixture()
        )

      assert updatedAppointment.id == appointment.id
      assert updatedAppointment.start_at == walltime_to_utc(new_start_at, timezone)
      assert updatedAppointment.end_at == walltime_to_utc(end_at, timezone)
    end

    test "insert_or_update_appointment/1 succeeds if instructor scheduled outside other appointment" do
      instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      aircraft = aircraft_fixture()
      type = "lesson"

      now = NaiveDateTime.utc_now() |> Timex.shift(hours: -4)

      {:ok, _} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 1),
          end_at: Timex.shift(now, hours: 3),
          instructor_user_id: instructor.id,
          user_id: student.id,
          aircraft_id: aircraft.id,
          type: type
        })

      other_student = user_fixture() |> assign_role("student")
      other_aircraft = aircraft_fixture()

      {:ok, _} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 4),
          end_at: Timex.shift(now, hours: 6),
          instructor_user_id: instructor.id,
          user_id: other_student.id,
          aircraft_id: other_aircraft.id,
          type: type
        })

      other_student = user_fixture() |> assign_role("student")
      other_aircraft = aircraft_fixture()

      {:ok, _} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: -1),
          end_at: Timex.shift(now, hours: 0),
          instructor_user_id: instructor.id,
          user_id: other_student.id,
          aircraft_id: other_aircraft.id,
          type: type
        })
    end

    test "insert_or_update_appointment/1 fails if instructor has overlapping appointment" do
      instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      aircraft = aircraft_fixture()
      type = "lesson"

      now = NaiveDateTime.utc_now() |> Timex.shift(hours: -4)

      {:ok, _} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 1),
          end_at: Timex.shift(now, hours: 3),
          instructor_user_id: instructor.id,
          user_id: student.id,
          aircraft_id: aircraft.id,
          type: type
        })

      other_student = user_fixture() |> assign_role("student")
      other_aircraft = aircraft_fixture()

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 2),
          end_at: Timex.shift(now, hours: 4),
          instructor_user_id: instructor.id,
          user_id: other_student.id,
          aircraft_id: other_aircraft.id,
          type: type
        })

      assert Enum.count(errors_on(changeset).instructor) == 1

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 0),
          end_at: Timex.shift(now, hours: 2),
          instructor_user_id: instructor.id,
          user_id: other_student.id,
          aircraft_id: other_aircraft.id,
          type: type
        })

      assert Enum.count(errors_on(changeset).instructor) == 1
    end

    test "insert_or_update_appointment/1 fails if user has overlapping appointment" do
      instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      aircraft = aircraft_fixture()
      type = "lesson"

      now = NaiveDateTime.utc_now() |> Timex.shift(hours: -4)

      {:ok, _} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 1),
          end_at: Timex.shift(now, hours: 3),
          instructor_user_id: instructor.id,
          user_id: student.id,
          aircraft_id: aircraft.id,
          type: type
        })

      other_instructor = user_fixture() |> assign_role("instructor")
      other_aircraft = aircraft_fixture()

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 2),
          end_at: Timex.shift(now, hours: 4),
          instructor_user_id: other_instructor.id,
          user_id: student.id,
          aircraft_id: other_aircraft.id,
          type: type
        })

      assert Enum.count(errors_on(changeset).renter_student) == 1

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 0),
          end_at: Timex.shift(now, hours: 2),
          instructor_user_id: other_instructor.id,
          user_id: student.id,
          aircraft_id: other_aircraft.id,
          type: type
        })

      assert Enum.count(errors_on(changeset).renter_student) == 1
    end

    test "insert_or_update_appointment/1 fails if aircraft has overlapping appointment" do
      instructor = user_fixture() |> assign_role("instructor")
      student = user_fixture() |> assign_role("student")
      aircraft = aircraft_fixture()
      type = "lesson"

      now = NaiveDateTime.utc_now() |> Timex.shift(hours: -4)

      {:ok, _} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 1),
          end_at: Timex.shift(now, hours: 3),
          instructor_user_id: instructor.id,
          user_id: student.id,
          aircraft_id: aircraft.id,
          type: type
        })

      other_instructor = user_fixture() |> assign_role("instructor")
      other_student = user_fixture() |> assign_role("student")

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 2),
          end_at: Timex.shift(now, hours: 4),
          instructor_user_id: other_instructor.id,
          user_id: other_student.id,
          aircraft_id: aircraft.id,
          type: type
        })

      assert Enum.count(errors_on(changeset).aircraft) == 1

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 0),
          end_at: Timex.shift(now, hours: 2),
          instructor_user_id: other_instructor.id,
          user_id: other_student.id,
          aircraft_id: aircraft.id,
          type: type
        })

      assert Enum.count(errors_on(changeset).aircraft) == 1
    end

    test "insert_or_update_appointment/1 fails if end_at is not greater than start_at" do
      now = NaiveDateTime.utc_now()
      type = "rental"

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 1),
          end_at: Timex.shift(now, hours: -1),
          user_id: student_fixture().id,
          aircraft_id: aircraft_fixture().id,
          instructor_user_id: instructor_fixture().id,
          type: type
        })

      assert Enum.count(errors_on(changeset).end_at) == 1

      {:error, changeset} =
        create_appointment(%{
          start_at: now,
          end_at: now,
          user_id: student_fixture().id,
          aircraft_id: aircraft_fixture().id,
          instructor_user_id: instructor_fixture().id,
          type: type
        })

      assert Enum.count(errors_on(changeset).end_at) == 1
    end

    test "insert_or_update_appointment/1 fails if neither instructor nor aircraft is selected" do
      now = NaiveDateTime.utc_now()

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 2),
          end_at: Timex.shift(now, hours: 4),
          user_id: student_fixture().id
        })

      assert Enum.count(errors_on(changeset).aircraft) == 1
    end

    test "insert_or_update_appointment/1 fails if user is not renter/student/instructor" do
      admin = user_fixture() |> assign_role("admin")
      now = NaiveDateTime.utc_now()
      type = "rental"

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 2),
          end_at: Timex.shift(now, hours: 4),
          user_id: admin.id,
          aircraft_id: aircraft_fixture().id,
          instructor_user_id: instructor_fixture().id,
          type: type
        })

      assert Enum.count(errors_on(changeset).renter_student) == 1

      for role <- ["renter", "student"] do
        {:ok, _} =
          create_appointment(%{
            start_at: Timex.shift(now, hours: 2),
            end_at: Timex.shift(now, hours: 4),
            user_id: (user_fixture() |> assign_role(role)).id,
            aircraft_id: aircraft_fixture().id,
            instructor_user_id: instructor_fixture().id,
            type: type
          })
      end
    end

    test "insert_or_update_appointment/1 fails if instructor user does not have instructor role" do
      now = NaiveDateTime.utc_now()
      type = "lesson"

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 2),
          end_at: Timex.shift(now, hours: 4),
          user_id: student_fixture().id,
          instructor_user_id: (user_fixture() |> assign_role("student")).id,
          aircraft_id: aircraft_fixture().id,
          type: type
        })

      assert Enum.count(errors_on(changeset).instructor) == 1
    end

    test "insert_or_update_appointment/1 fails if instructor and user are same user" do
      now = NaiveDateTime.utc_now()

      user =
        user_fixture()
        |> assign_roles(["instructor", "student"])

      {:error, changeset} =
        create_appointment(%{
          start_at: Timex.shift(now, hours: 2),
          end_at: Timex.shift(now, hours: 4),
          user_id: user.id,
          instructor_user_id: user.id
        })

      assert Enum.count(errors_on(changeset).instructor) == 1
    end

    ##
    # get_appointments(options)
    ##

    test "get_appointments/2 returns appointments within range" do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})

      _appointment2 =
        appointment_fixture(%{start_at: ~N[2038-03-02 22:59:59], end_at: ~N[2038-03-02 23:59:59]})

      appointment3 =
        appointment_fixture(%{start_at: ~N[2038-03-03 22:59:59], end_at: ~N[2038-03-03 23:59:59]})

      appointments =
        Scheduling.get_appointments(
          %{
            "from" => "2038-03-03T00:00:00Z",
            "to" => "2038-03-04T00:00:00Z"
          },
          default_school_fixture()
        )

      assert [%Appointment{}, %Appointment{}] = appointments

      appointmentIds = Enum.map(appointments, & &1.id)

      assert MapSet.new(appointmentIds) == MapSet.new([appointment1.id, appointment3.id])
    end

    test "get_appointments/2 returns appointments starting after `start_at_after` value" do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})

      _appointment2 =
        appointment_fixture(%{start_at: ~N[2038-03-02 22:59:59], end_at: ~N[2038-03-02 23:59:59]})

      appointments =
        Scheduling.get_appointments(
          %{
            "start_at_after" => "2038-03-03T00:00:00Z"
          },
          default_school_fixture()
        )

      assert [%Appointment{id: id}] = appointments

      assert id == appointment1.id
    end

    test "get_appointments/2 returns appointments for user" do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})

      _appointment2 =
        appointment_fixture(%{start_at: ~N[2038-03-02 22:59:59], end_at: ~N[2038-03-02 23:59:59]})

      id = appointment1.id

      assert [%Appointment{id: ^id}] =
               Scheduling.get_appointments(
                 %{
                   "user_id" => appointment1.user.id
                 },
                 default_school_fixture()
               )
    end

    test "get_appointments/2 returns appointments by status" do
      appointment1 =
        appointment_fixture(%{
          status: :pending,
          start_at: ~N[2038-03-03 10:00:00],
          end_at: ~N[2038-03-03 11:00:00]
        })

      appointment_fixture(%{
        status: :paid,
        start_at: ~N[2038-03-02 22:59:59],
        end_at: ~N[2038-03-02 23:59:59]
      })

      id = appointment1.id

      assert [%Appointment{id: ^id}] =
               Scheduling.get_appointments(
                 %{"status" => 0},
                 default_school_fixture()
               )
    end

    test "get_appointments/2 returns appointments for instructor" do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})

      _appointment2 =
        appointment_fixture(%{start_at: ~N[2038-03-02 22:59:59], end_at: ~N[2038-03-02 23:59:59]})

      id = appointment1.id

      assert [%Appointment{id: ^id}] =
               Scheduling.get_appointments(
                 %{
                   "instructor_user_id" => appointment1.instructor_user.id
                 },
                 default_school_fixture()
               )
    end

    test "get_appointments/2 returns appointments for aircraft" do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})

      _appointment2 =
        appointment_fixture(%{start_at: ~N[2038-03-02 22:59:59], end_at: ~N[2038-03-02 23:59:59]})

      id = appointment1.id

      assert [%Appointment{id: ^id}] =
               Scheduling.get_appointments(
                 %{
                   "aircraft_id" => appointment1.aircraft.id
                 },
                 default_school_fixture()
               )
    end

    test "get_appointments/2 returns appointments for aircraft & student" do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})

      _appointment2 =
        appointment_fixture(
          %{start_at: ~N[2038-03-02 22:59:59], end_at: ~N[2038-03-02 23:59:59]},
          appointment1.user
        )

      id = appointment1.id

      assert [%Appointment{id: ^id}] =
               Scheduling.get_appointments(
                 %{
                   "user_id" => appointment1.user.id,
                   "aircraft_id" => appointment1.aircraft.id
                 },
                 default_school_fixture()
               )
    end

    test "get_appointment/2 returns correct timezone" do
      appointment =
        appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})
        |> Repo.preload(:school)

      assert Scheduling.get_appointment(appointment.id, appointment).start_at ==
               appointment.start_at
    end

    test "delete_appointment/3 deletes appointment" do
      admin = admin_fixture()

      appointment = appointment_fixture()

      Scheduling.delete_appointment(appointment.id, admin, appointment)

      appointment = Repo.get(Appointment, appointment.id)

      assert appointment.archived
    end
  end

  describe "calculate_appointments_duration/2 that returns string time duration" do
    test "by passing appointments having no time difference to validate zero value difference" do
      appointment =
        appointment_fixture(%{start_at: ~N[2030-06-03 10:00:00], end_at: ~N[2030-06-03 10:00:01]})

      assert Scheduling.calculate_appointments_duration([appointment]) == "0h  0m"
    end

    test "by passing appointments having valid time difference" do
      appointment =
        appointment_fixture(%{start_at: ~N[2030-06-03 10:00:00], end_at: ~N[2030-06-03 11:30:00]})

      assert Scheduling.calculate_appointments_duration([appointment]) == "1h  30m"
    end

    test "by passing appointments having more than 2 days time difference" do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2030-06-03 10:00:00], end_at: ~N[2030-06-04 10:43:00]})

      appointment2 =
        appointment_fixture(%{start_at: ~N[2030-06-07 10:43:00], end_at: ~N[2030-06-08 13:40:00]})

      assert Scheduling.calculate_appointments_duration([appointment1, appointment2]) ==
               "51h  40m"
    end

    test "by passing appointments having more than 30 days time difference" do
      appointment1 =
        appointment_fixture(%{start_at: ~N[2030-06-03 10:00:00], end_at: ~N[2030-06-23 10:43:00]})

      appointment2 =
        appointment_fixture(%{start_at: ~N[2030-06-23 10:43:00], end_at: ~N[2030-06-29 11:40:00]})

      appointment3 =
        appointment_fixture(%{start_at: ~N[2030-06-29 11:40:00], end_at: ~N[2030-07-03 13:51:00]})

      assert Scheduling.calculate_appointments_duration([appointment1, appointment2, appointment3]) ==
               "723h  51m"
    end
  end

  describe "insert_or_update_unavailability/3" do
    @start_at ~N[2038-03-03 10:00:00]
    @end_at ~N[2038-03-03 12:00:00]

    test "inserts unavailability" do
      instructor = instructor_fixture()

      {:ok, unavailability} =
        Scheduling.insert_or_update_unavailability(
          %Unavailability{},
          %{
            instructor_user_id: instructor.id,
            belongs: "Instructor",
            start_at: @start_at,
            end_at: @end_at,
            reason: "time_off",
            note: "Something crazy"
          },
          default_school_fixture()
        )

      assert unavailability.instructor_user_id == instructor.id
      assert unavailability.start_at == walltime_to_utc(@start_at, instructor.school.timezone)
      assert unavailability.end_at == walltime_to_utc(@end_at, instructor.school.timezone)
      assert unavailability.type == "time_off"
      assert unavailability.note == "Something crazy"
    end

    @tag :wip
    test "can't overlap existing unavailability instructor" do
      instructor = instructor_fixture()

      {:ok, _} =
        Scheduling.insert_or_update_unavailability(
          %Unavailability{},
          %{
            instructor_user_id: instructor.id,
            belongs: "Instructor",
            start_at: @start_at,
            end_at: @end_at
          },
          default_school_fixture()
        )

      assert {:error, _} =
               Scheduling.insert_or_update_unavailability(
                 %Unavailability{},
                 %{
                   instructor_user_id: instructor.id,
                   belongs: "Instructor",
                   start_at: @start_at,
                   end_at: @end_at
                 },
                 default_school_fixture()
               )
    end

    @tag :wip
    test "can't overlap existing unavailability aircraft" do
      aircraft = aircraft_fixture()

      {:ok, _} =
        Scheduling.insert_or_update_unavailability(
          %Unavailability{},
          %{
            aircraft_id: aircraft.id,
            belongs: "Aircraft",
            start_at: @start_at,
            end_at: @end_at
          },
          default_school_fixture()
        )

      assert {:error, _} =
               Scheduling.insert_or_update_unavailability(
                 %Unavailability{},
                 %{
                   aircraft_id: aircraft.id,
                   belongs: "Aircraft",
                   start_at: @start_at,
                   end_at: @end_at
                 },
                 default_school_fixture()
               )
    end

    test "can overlap existing appointment" do
      instructor = instructor_fixture()
      admin = admin_fixture()
      type = "lesson"

      {:ok, _} =
        Scheduling.insert_or_update_appointment(
          %Appointment{},
          %{
            user_id: student_fixture().id,
            instructor_user_id: instructor.id,
            aircraft_id: aircraft_fixture().id,
            start_at: @start_at,
            end_at: @end_at,
            type: type
          },
          admin,
          default_school_fixture()
        )

      assert {:ok, _} =
               Scheduling.insert_or_update_unavailability(
                 %Unavailability{},
                 %{
                   instructor_user_id: instructor.id,
                   belongs: "Instructor",
                   start_at: @start_at,
                   end_at: @end_at
                 },
                 default_school_fixture()
               )
    end

    test "updates existing unavailability" do
      instructor = instructor_fixture()

      {:ok, unavailability} =
        Scheduling.insert_or_update_unavailability(
          %Unavailability{},
          %{
            instructor_user_id: instructor.id,
            belongs: "Instructor",
            start_at: @start_at,
            end_at: @end_at
          },
          default_school_fixture()
        )

      {:ok, unavailability} =
        Scheduling.insert_or_update_unavailability(
          unavailability,
          %{
            start_at: Timex.shift(@start_at, hours: -1)
          },
          default_school_fixture()
        )

      assert unavailability.start_at ==
               walltime_to_utc(Timex.shift(@start_at, hours: -1), instructor.school.timezone)
    end

    test "error if no instructor" do
      {:error, _unavailability} =
        Scheduling.insert_or_update_unavailability(
          %Unavailability{},
          %{
            belongs: "Instructor",
            start_at: @start_at,
            end_at: @end_at
          },
          default_school_fixture()
        )
    end

    test "error if no aircraft" do
      {:error, _unavailability} =
        Scheduling.insert_or_update_unavailability(
          %Unavailability{},
          %{
            belongs: "Aircraft",
            start_at: @start_at,
            end_at: @end_at
          },
          default_school_fixture()
        )
    end

    test "fails if end_at is not greater than start_at" do
      now = NaiveDateTime.utc_now()

      {:error, changeset} =
        Scheduling.insert_or_update_unavailability(
          %Unavailability{},
          %{
            instructor_user_id: instructor_fixture().id,
            belongs: "Instructor",
            start_at: Timex.shift(now, hours: 1),
            end_at: Timex.shift(now, hours: -1)
          },
          default_school_fixture()
        )

      assert Enum.count(errors_on(changeset).end_at) == 1

      {:error, changeset} =
        Scheduling.insert_or_update_unavailability(
          %Unavailability{},
          %{
            instructor_user_id: instructor_fixture().id,
            belongs: "Instructor",
            start_at: now,
            end_at: now
          },
          default_school_fixture()
        )

      assert Enum.count(errors_on(changeset).end_at) == 1
    end
  end
end
