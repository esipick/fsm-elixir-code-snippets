defmodule Flight.Scheduling.AvailabilityTest do
  use Flight.DataCase, async: false

  import Flight.Auth.Permission, only: [permission_slug: 3]

  alias Flight.Scheduling
  alias Flight.Scheduling.{Availability}

  describe "instructor_availability" do
    test "returns status of all instructors" do
      date = ~N[2018-03-03 16:00:00]

      _admin = user_fixture() |> assign_role("admin")
      _student = user_fixture() |> assign_role("student")
      available_instructor = user_fixture() |> assign_role("instructor")
      available_instructor2 = user_fixture() |> assign_role("instructor")
      unavailable_instructor = user_fixture() |> assign_role("instructor")

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          instructor_user_id: unavailable_instructor.id
        })

      # unset instructor_user_id during same time period, to make sure nil doesn't screw things up
      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          aircraft_id: aircraft_fixture().id
        })

      available =
        Availability.instructor_availability(
          Timex.shift(date, hours: 1),
          Timex.shift(date, hours: 3)
        )

      assert Enum.find(available, &(&1.user.id == available_instructor.id)).status == :available

      assert Enum.find(available, &(&1.user.id == available_instructor2.id)).status == :available

      assert Enum.find(available, &(&1.user.id == unavailable_instructor.id)).status ==
               :unavailable
    end
  end

  describe "student_availability" do
    test "returns status of all students" do
      date = ~N[2018-03-03 16:00:00]

      _admin = user_fixture() |> assign_role("admin")
      _instructor = user_fixture() |> assign_role("instructor")
      available_student = user_fixture() |> assign_role("student")
      available_student2 = user_fixture() |> assign_role("student")
      unavailable_student = user_fixture() |> assign_role("student")

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: unavailable_student.id,
          aircraft_id: aircraft_fixture().id
        })

      available =
        Availability.student_availability(
          Timex.shift(date, hours: 1),
          Timex.shift(date, hours: 3)
        )

      assert Enum.find(available, &(&1.user.id == available_student.id)).status == :available

      assert Enum.find(available, &(&1.user.id == available_student2.id)).status == :available

      assert Enum.find(available, &(&1.user.id == unavailable_student.id)).status == :unavailable
    end
  end

  describe "aircraft_availability" do
    test "returns status of all aircraft" do
      date = ~N[2018-03-03 16:00:00]

      available_aircraft = aircraft_fixture()
      available_aircraft2 = aircraft_fixture()
      available_aircraft3 = aircraft_fixture()
      unavailable_aircraft = aircraft_fixture()
      unavailable_aircraft2 = aircraft_fixture()
      unavailable_aircraft3 = aircraft_fixture()
      unavailable_aircraft4 = aircraft_fixture()
      unavailable_aircraft5 = aircraft_fixture()
      unavailable_aircraft6 = aircraft_fixture()

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: Timex.shift(date, hours: 5),
          end_at: Timex.shift(date, hours: 6),
          user_id: student_fixture().id,
          aircraft_id: available_aircraft2.id
        })

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: Timex.shift(date, hours: -1),
          end_at: Timex.shift(date, hours: 1),
          user_id: student_fixture().id,
          aircraft_id: available_aircraft3.id
        })

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          aircraft_id: unavailable_aircraft.id
        })

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: Timex.shift(date, hours: -1),
          end_at: Timex.shift(date, hours: 6),
          user_id: student_fixture().id,
          aircraft_id: unavailable_aircraft2.id
        })

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: Timex.shift(date, hours: 2),
          end_at: Timex.shift(date, hours: 3),
          user_id: student_fixture().id,
          aircraft_id: unavailable_aircraft3.id
        })

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: Timex.shift(date, hours: 3),
          end_at: Timex.shift(date, hours: 7),
          user_id: student_fixture().id,
          aircraft_id: unavailable_aircraft4.id
        })

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: Timex.shift(date, hours: 2),
          end_at: Timex.shift(date, hours: 5),
          user_id: student_fixture().id,
          aircraft_id: unavailable_aircraft5.id
        })

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: Timex.shift(date, hours: 1),
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          aircraft_id: unavailable_aircraft6.id
        })

      # unset aircraft_id during same time period, to make sure nil doesn't screw things up
      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          instructor_user_id: (user_fixture() |> assign_role("instructor")).id
        })

      available =
        Availability.aircraft_availability(
          Timex.shift(date, hours: 1),
          Timex.shift(date, hours: 5)
        )

      assert Enum.find(available, &(&1.aircraft.id == available_aircraft.id)).status == :available

      assert Enum.find(available, &(&1.aircraft.id == available_aircraft2.id)).status ==
               :available

      assert Enum.find(available, &(&1.aircraft.id == available_aircraft3.id)).status ==
               :available

      assert Enum.find(available, &(&1.aircraft.id == unavailable_aircraft.id)).status ==
               :unavailable

      assert Enum.find(available, &(&1.aircraft.id == unavailable_aircraft2.id)).status ==
               :unavailable

      assert Enum.find(available, &(&1.aircraft.id == unavailable_aircraft3.id)).status ==
               :unavailable

      assert Enum.find(available, &(&1.aircraft.id == unavailable_aircraft4.id)).status ==
               :unavailable

      assert Enum.find(available, &(&1.aircraft.id == unavailable_aircraft5.id)).status ==
               :unavailable

      assert Enum.find(available, &(&1.aircraft.id == unavailable_aircraft6.id)).status ==
               :unavailable
    end
  end

  describe "user_with_permission_status" do
    test "returns available" do
      date = ~N[2018-03-03 16:00:00]

      user = user_fixture() |> assign_role("instructor")

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          instructor_user_id: user.id
        })

      assert Availability.user_with_permission_status(
               permission_slug(:appointment_instructor, :modify, :personal),
               user.id,
               Timex.shift(date, hours: 4),
               Timex.shift(date, hours: 6)
             ) == :available
    end

    test "returns unavailable" do
      date = ~N[2018-03-03 16:00:00]

      user = user_fixture() |> assign_role("instructor")

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          instructor_user_id: user.id
        })

      assert Availability.user_with_permission_status(
               permission_slug(:appointment_instructor, :modify, :personal),
               user.id,
               Timex.shift(date, hours: 1),
               Timex.shift(date, hours: 3)
             ) == :unavailable
    end

    test "returns invalid" do
      date = ~N[2018-03-03 16:00:00]

      user = user_fixture() |> assign_role("student")

      assert Availability.user_with_permission_status(
               permission_slug(:appointment_instructor, :modify, :personal),
               user.id,
               Timex.shift(date, hours: 4),
               Timex.shift(date, hours: 6)
             ) == :invalid
    end
  end

  describe "aircraft_status" do
    test "returns available" do
      date = ~N[2018-03-03 16:00:00]

      aircraft = aircraft_fixture()

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          aircraft_id: aircraft.id
        })

      assert Availability.aircraft_status(
               aircraft.id,
               Timex.shift(date, hours: 4),
               Timex.shift(date, hours: 6)
             ) == :available
    end

    test "returns unavailable" do
      date = ~N[2018-03-03 16:00:00]

      aircraft = aircraft_fixture()

      {:ok, _} =
        Scheduling.create_appointment(%{
          start_at: date,
          end_at: Timex.shift(date, hours: 2),
          user_id: student_fixture().id,
          aircraft_id: aircraft.id
        })

      assert Availability.aircraft_status(
               aircraft.id,
               Timex.shift(date, hours: 1),
               Timex.shift(date, hours: 3)
             ) == :unavailable
    end

    test "returns invalid" do
      date = ~N[2018-03-03 16:00:00]

      aircraft = aircraft_fixture()

      assert Availability.aircraft_status(
               aircraft.id + 1,
               Timex.shift(date, hours: 4),
               Timex.shift(date, hours: 6)
             ) == :invalid
    end
  end
end
