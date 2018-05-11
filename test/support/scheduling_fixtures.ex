defmodule Flight.SchedulingFixtures do
  alias Flight.Scheduling.{Aircraft, Inspection, DateInspection, TachInspection}
  alias Flight.{Repo}

  def aircraft_fixture(attrs \\ %{}) do
    invitation =
      %Aircraft{
        make: "Sesna",
        model: "Thing",
        tail_number: Flight.Random.hex(15),
        serial_number: Flight.Random.hex(15),
        ifr_certified: true,
        equipment: Flight.Random.hex(15),
        simulator: true,
        last_tach_time: 400,
        rate_per_hour: 130,
        block_rate_per_hour: 120
      }
      |> Aircraft.changeset(attrs)
      |> Repo.insert!()

    invitation
  end

  def date_inspection_fixture(attrs \\ %{}, aircraft \\ aircraft_fixture()) do
    {:ok, date_inspection} =
      %DateInspection{
        expiration: Date.utc_today(),
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
