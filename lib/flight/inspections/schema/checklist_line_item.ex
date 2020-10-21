defmodule Flight.Inspections.CheckListLineItem do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Inspections.{
        CheckListDetails,
        CheckListLineItem
    }

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "checklist_line_items" do
        field(:part_name, :string, null: false)
        field(:part_number, :string, null: false)
        field(:serial_number, :string, null: false)
        field(:cost, :integer, default: 0)

        belongs_to(:checklist_details, CheckListDetails, type: :binary_id)

        timestamps([inserted_at: :created_at])
    end

    def required_fields(), do: ~w(part_name part_number serial_number checklist_details_id)a

    def changeset(%CheckListLineItem{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
        |> foreign_key_constraint(:checklist_details_id, name: :checklist_line_items_checklist_details_id_fkey, message: "Checklist Details not found.")
    end
end