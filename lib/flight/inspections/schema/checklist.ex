defmodule Flight.Inspections.CheckList do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Accounts.School
    alias Flight.Inspections.{
        CheckList,
        Maintenance
    }

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "checklist" do
        field(:name, :string, null: false)
        field(:description, :string, null: true)

        field :school_id, :id, null: false

        belongs_to(:school, School, define_field: false, foreign_key: :school_id)
        many_to_many(:maintenance, Maintenance, join_through: "maintenance_checklist")

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(name school_id)a

    def changeset(%CheckList{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
        |> foreign_key_constraint(:school_id, name: :checklist_school_id_fkey, message: "No school found with id.")
    end
end