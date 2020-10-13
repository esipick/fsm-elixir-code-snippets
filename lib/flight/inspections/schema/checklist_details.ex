defmodule Flight.Inspections.CheckListDetails do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Inspections.{
        CheckListDetails,
        AircraftMaintenance,
        MaintenanceCheckList
    }

    @allowed_status ["pending", "completed"]

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "checklist_details" do
        field(:status, :string, default: "pending")
        field(:notes, :string, null: true)

        belongs_to(:aircraft_maintenance, AircraftMaintenance, type: :binary_id)
        belongs_to(:maintenance_checklist, MaintenanceCheckList, type: :binary_id)

        timestamps([inserted_at: :created_at])
    end

    def required_fields(), do: ~w(status aircraft_maintenance_id maintenance_checklist_id)a

    def changeset(%CheckListDetails{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
        |> normalize_status
        |> validate_inclusion(:status, @allowed_status)
        |> foreign_key_constraint(:aircraft_maintenance_id, name: :checklist_details_aircraft_maintenance_id_fkey, message: "Aircraft Maintenance not found.")
        |> foreign_key_constraint(:maintenance_checklist_id, name: :checklist_details_maintenance_checklist_id_fkey, message: "Maintenance Checklist not found.")
    end

    def normalize_status(%Ecto.Changeset{valid?: true, changes: %{status: status}} = changeset) do
        status = status || "pending"
        status = 
            status
            |> String.downcase

        put_change(changeset, :status, status)
    end
    def normalize_status(changeset), do: changeset
end