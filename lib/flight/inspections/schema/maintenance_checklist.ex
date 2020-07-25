defmodule Flight.Inspections.MaintenanceCheckList do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Inspections.MaintenanceCheckList
    alias Flight.Inspections.{
        Maintenance,
        CheckList
    }

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "maintenance_checklist" do
        field(:maintenance_id, :binary_id, null: false)
        field(:checklist_id, :binary_id, null: false)

        belongs_to(:maintenance, Maintenance, define_field: false, foreign_key: :maintenance_id)
        belongs_to(:checklist, CheckList, define_field: false, foreign_key: :checklist_id)

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(checklist_id maintenance_id)

    def changeset(%MaintenanceCheckList{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
        |> unique_constraint([:maintenance_id, :checklist_id], message: "Record already exists.")
    end
end