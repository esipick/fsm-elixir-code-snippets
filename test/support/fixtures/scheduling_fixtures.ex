defmodule Flight.SchedulingFixtures do
  import Flight.{AccountsFixtures, Walltime}

  alias Flight.Scheduling.{
    Aircraft,
    Appointment,
    Inspection,
    DateInspection,
    TachInspection,
    Unavailability
  }

  alias Flight.SchoolAssets.Room

  alias Flight.{Repo}

  def aircraft_fixture(params \\ %{}, school \\ default_school_fixture()) do
    attrs = MapUtil.atomize_shallow(params)

    %Aircraft{
      make: "Sesna",
      model: "Thing",
      tail_number: "N1546",
      serial_number: "54-54615",
      ifr_certified: true,
      equipment: Flight.Random.hex(15),
      last_tach_time: 400,
      last_hobbs_time: 400,
      rate_per_hour: 130,
      block_rate_per_hour: 120,
      school_id: school.id,
      name: if(attrs[:simulator], do: "Simulator", else: nil)
    }
    |> Aircraft.changeset(attrs)
    |> Repo.insert!()
  end

  def simulator_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    Map.merge(attrs, %{simulator: true})
    |> aircraft_fixture(school)
  end

  def appointment_fixture(
        attrs \\ %{},
        user \\ student_fixture(),
        instructor \\ instructor_fixture(),
        aircraft \\ aircraft_fixture(),
        school \\ default_school_fixture(),
        type \\ "lesson"
      ) do
    date = ~N[2038-03-03 10:00:00]

    start_at =
      Map.get(attrs, :start_at, Timex.shift(date, hours: 2))
      |> walltime_to_utc(school.timezone)

    end_at =
      Map.get(attrs, :end_at, Timex.shift(date, hours: 4)) |> walltime_to_utc(school.timezone)

    appointment =
      %Appointment{
        start_at: start_at,
        end_at: end_at,
        user_id: user.id,
        instructor_user_id: instructor.id,
        aircraft_id: aircraft.id,
        school_id: school.id,
        type: type
      }
      |> Appointment.changeset(attrs, school.timezone)
      |> Repo.insert!()

    %{appointment | aircraft: aircraft, instructor_user: instructor, user: user}
  end

  def past_appointment_fixture(
        attrs \\ %{},
        user \\ student_fixture(),
        instructor \\ instructor_fixture(),
        aircraft \\ aircraft_fixture(),
        school \\ default_school_fixture(),
        type \\ "lesson"
      ) do
    date = ~N[2018-03-03 10:00:00]

    start_at =
      Map.get(attrs, :start_at, Timex.shift(date, hours: 2))
      |> walltime_to_utc(school.timezone)

    end_at =
      Map.get(attrs, :end_at, Timex.shift(date, hours: 4)) |> walltime_to_utc(school.timezone)

    appointment =
      %Appointment{
        start_at: start_at,
        end_at: end_at,
        user_id: user.id,
        instructor_user_id: instructor.id,
        aircraft_id: aircraft.id,
        school_id: school.id,
        type: type
      }
      |> Appointment.__test_changeset(attrs, school.timezone)
      |> Repo.insert!()

    %{appointment | aircraft: aircraft, instructor_user: instructor, user: user}
  end

  def unavailability_fixture(
        attrs \\ %{},
        instructor \\ instructor_fixture(),
        aircraft \\ nil,
        school \\ default_school_fixture()
      ) do
    date = ~N[2038-03-03 10:00:00]

    start_at =
      Map.get(attrs, :start_at, Timex.shift(date, hours: 2))
      |> walltime_to_utc(school.timezone)

    end_at =
      Map.get(attrs, :end_at, Timex.shift(date, hours: 4)) |> walltime_to_utc(school.timezone)

    unavailability =
      %Unavailability{
        start_at: start_at,
        end_at: end_at,
        instructor_user_id: if(instructor, do: instructor.id, else: nil),
        aircraft_id: if(aircraft, do: aircraft.id, else: nil),
        belongs: if(instructor, do: "Instructor", else: "Aircraft"),
        school_id: school.id
      }
      |> Unavailability.changeset(attrs, school.timezone)
      |> Repo.insert!()

    %{unavailability | aircraft: aircraft, instructor_user: instructor}
  end

  def date_inspection_fixture(attrs \\ %{}, aircraft \\ aircraft_fixture()) do
    {:ok, date_inspection} =
      %DateInspection{
        expiration: Date.add(Date.utc_today(), 1),
        aircraft_id: aircraft.id,
        name: "Annual"
      }
      |> DateInspection.changeset(attrs)
      |> Ecto.Changeset.apply_action(:insert)

    inspection =
      %Inspection{}
      |> Inspection.changeset(DateInspection.attrs(date_inspection))
      |> Repo.insert!()

    %{inspection | aircraft: aircraft}
  end

  def tach_inspection_fixture(attrs \\ %{}, aircraft \\ aircraft_fixture()) do
    {:ok, tach_inspection} =
      %TachInspection{
        tach_time: 300,
        aircraft_id: aircraft.id,
        name: "100Hr"
      }
      |> TachInspection.changeset(attrs)
      |> Ecto.Changeset.apply_action(:insert)

    inspection =
      %Inspection{}
      |> Inspection.changeset(TachInspection.attrs(tach_inspection))
      |> Repo.insert!()

    %{inspection | aircraft: aircraft}
  end

  def room_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    %Room{
      capacity: 5,
      location: "Millenium Street 5",
      resources: Flight.Random.hex(15),
      rate_per_hour: 130,
      block_rate_per_hour: 120,
      school_id: school.id
    }
    |> Room.changeset(attrs)
    |> Repo.insert!()
  end
end
