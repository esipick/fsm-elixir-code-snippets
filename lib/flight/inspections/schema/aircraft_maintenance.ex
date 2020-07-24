defmodule Flight.Inspections.AircraftMaintenance do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Scheduling.Aircraft
    alias Flight.Inspections.{
        Maintenance,
        AircraftMaintenance
    }

    @primary_key false
    schema "aircraft_maintenance" do
        field(:aircraft_id, :id, primary_key: true)
        field(:maintenance_id, :binary_id, primary_key: true)

        field(:tach_hours_diff, :integer, default: 0)
        field(:start_time, :naive_datetime, null: true)
        field(:end_time, :naive_datetime, null: true)

        belongs_to(:aircraft, Aircraft, define_field: false, foreign_key: :aircraft_id)
        belongs_to(:maintenance, Maintenance, define_field: false, foreign_key: :maintenance_id)

        timestamps()
    end

    defp required_fields(), do: ~w(aircraft_id maintenance_id)

    def changeset(%AircraftMaintenance{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
    end
end