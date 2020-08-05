defmodule Flight.Inspections.AircraftMaintenance do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Scheduling.Aircraft
    alias Flight.Inspections.{
        Maintenance,
        AircraftMaintenance
    }

    @allowed_status ["pending", "completed"]

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "aircraft_maintenance" do
        field(:aircraft_id, :id, null: false)
        field(:maintenance_id, :binary_id, null: false)

        field(:start_tach_hours, :integer, default: 0) # at this tach time, the event is gonna start.
        field(:start_time, :naive_datetime, null: true)
        field(:end_time, :naive_datetime, null: true)

        field(:status, :string, default: "pending")

        belongs_to(:aircraft, Aircraft, define_field: false, foreign_key: :aircraft_id)
        belongs_to(:maintenance, Maintenance, define_field: false, foreign_key: :maintenance_id)

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(aircraft_id maintenance_id)a

    def changeset(%AircraftMaintenance{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
        |> normalize_status
        |> validate_inclusion(:status, @allowed_status)
        |> unique_constraint([:aircraft_id, :maintenance_id], message: "Aircraft already assigned.")
        |> foreign_key_constraint(:aircraft_id, name: :aircraft_maintenance_aircraft_id_fkey, message: "No aircraft with id: #{inspect Map.get(params, "aircraft_id")} found.")
    end

    def normalize_status(%Ecto.Changeset{valid?: true, changes: %{status: status}}) do
        status = status || "pending"
        String.downcase(status)
    end
    def normalize_status(changeset), do: changeset
end