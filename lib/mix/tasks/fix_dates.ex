defmodule Mix.Tasks.FixDates do
  use Mix.Task

  import Ecto.Query
  import Flight.Walltime
  alias Flight.{Repo, Scheduling.Appointment, Scheduling.Unavailability}

  @shortdoc "Fixes start_at and end_at dates in appointments and unavailabilities"
  def run(_) do
    [:postgrex, :ecto, :tzdata]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    from = ~N[2018-08-27 06:12:00]

    IO.puts("Get appointments")

    appointments =
      Appointment
      |> where([a], a.inserted_at > ^from)
      |> Repo.all()
      |> Repo.preload([:aircraft, :instructor_user, :school, :transaction, :user, :mechanic_user])

    IO.puts("Update appointments")

    for appointment <- appointments do
      timezone = appointment.school.timezone
      start_at = appointment.start_at
      end_at = appointment.end_at

      IO.puts("Wrong dates: #{start_at} - #{end_at}")

      new_start_at = utc_to_walltime(utc_to_walltime(start_at, timezone), timezone)
      new_end_at = utc_to_walltime(utc_to_walltime(end_at, timezone), timezone)

      attrs = %{end_at: new_end_at, start_at: new_start_at}

      IO.puts("Update appointment with id: #{appointment.id}")

      appointment =
        appointment
        |> Appointment.__test_changeset(attrs, timezone)
        |> Repo.update!()

      IO.puts("New dates: #{appointment.start_at} - #{appointment.end_at}")
    end

    IO.puts("Get unavailabilities")

    unavailabilities =
      Unavailability
      |> where([a], a.inserted_at > ^from)
      |> Repo.all()
      |> Repo.preload([:aircraft, :instructor_user, :school])

    IO.puts("Update unavailabilities")

    for unavailability <- unavailabilities do
      timezone = unavailability.school.timezone
      start_at = unavailability.start_at
      end_at = unavailability.end_at

      IO.puts("Wrong dates: #{start_at} - #{end_at}")

      new_start_at = utc_to_walltime(start_at, timezone)
      new_end_at = utc_to_walltime(end_at, timezone)

      attrs = %{end_at: new_end_at, start_at: new_start_at}

      IO.puts("Update unavailability with id: #{unavailability.id}")

      unavailability =
        unavailability
        |> Unavailability.__test_changeset(attrs, timezone)
        |> Repo.update!()

      IO.puts("New dates: #{unavailability.start_at} - #{unavailability.end_at}")
    end

    IO.puts("Task completed successfully.")
  end
end
