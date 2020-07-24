defmodule Flight.Inspections.CheckList do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Inspections.{
        CheckList,
        Maintenance
    }

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "checklist" do
        field(:name, :string, null: false)
        field(:description, :string, null: true)

        many_to_many(:maintenance, Maintenance, join_through: "maintenance_checklist")

        timestamps()
    end

    defp required_fields(), do: ~w(name)a

    def changeset(%CheckList{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(__MODULE__.required_fields)
    end
end