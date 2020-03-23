defmodule Flight.SchedulingFixtures do
  alias Flight.Scheduling.{
    Aircraft,
    Appointment,
    Inspection,
    DateInspection,
    TachInspection,
    Unavailability
  }

  alias Flight.{Repo}

  import Flight.AccountsFixtures

  def aircraft_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    aircraft =
      %Aircraft{
        make: "Sesna",
        model: "Thing",
        tail_number: "N1546",
        serial_number: "54-54615",
        ifr_certified: true,
        equipment: Flight.Random.hex(15),
        simulator: true,
        last_tach_time: 400,
        last_hobbs_time: 400,
        rate_per_hour: 130,
        block_rate_per_hour: 120,
        school_id: school.id
      }
      |> Aircraft.changeset(attrs)
      |> Repo.insert!()

    aircraft
  end

  def appointment_fixture(
        attrs \\ %{},
        user \\ student_fixture(),
        instructor \\ instructor_fixture(),
        aircraft \\ aircraft_fixture(),
        school \\ default_school_fixture(),
        type \\ "lesson"
      ) do
    date = ~N[2018-03-03 10:00:00]

    appointment =
      %Appointment{
        start_at: Timex.shift(date, hours: 2),
        end_at: Timex.shift(date, hours: 4),
        user_id: user.id,
        instructor_user_id: instructor.id,
        aircraft_id: aircraft.id,
        school_id: school.id,
        type: type
      }
      |> Appointment.changeset(attrs)
      |> Appointment.apply_timezone_changeset(school.timezone)
      |> Repo.insert!()

    %{appointment | aircraft: aircraft, instructor_user: instructor, user: user}
  end

  def unavailability_fixture(
        attrs \\ %{},
        instructor \\ instructor_fixture(),
        aircraft \\ nil,
        school \\ default_school_fixture()
      ) do
    date = ~N[2018-03-03 10:00:00]

    unavailability =
      %Unavailability{
        start_at: Timex.shift(date, hours: 2),
        end_at: Timex.shift(date, hours: 4),
        instructor_user_id: if(instructor, do: instructor.id, else: nil),
        aircraft_id: if(aircraft, do: aircraft.id, else: nil),
        belongs: if(instructor, do: "Instructor", else: "Aircraft"),
        school_id: school.id
      }
      |> Unavailability.changeset(attrs)
      |> Unavailability.apply_timezone_changeset(school.timezone)
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
end
