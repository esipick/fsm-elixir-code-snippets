defmodule Flight.Inspections.Maintenance do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Inspections.{
        Maintenance,
        CheckList
    }

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "maintenance" do
        field(:name, :string, null: false)
        field(:description, :string, null: true)
        
        field(:tach_hours, :integer, default: 0) # the event will occur after this many tach hours
        field(:no_of_days, :integer, default: 0) # Or the event will occur in this many days

        many_to_many(:checklists, CheckList, join_through: "maintenance_checklist")

        timestamps()
    end

    def required_fields(), do: ~w(name)a

    def changeset(%Maintenance{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(__MODULE__.required_fields)
        |> validate_occurance_hours
    end

    def validate_occurance_hours(%Ecto.Changeset{valid?: true} = changeset) do
        tach_hours = get_change(changeset, :tach_hours) || get_field(changeset, :tach_hours) || 0
        days = get_change(changeset, :no_of_days) || get_field(changeset, :no_of_days) || 0

        if tach_hours <= 0 && days <= 0 do
            changeset
            |> add_error(:tach_hours, "Must be greater than 0")
            |> add_error(:no_of_days, "Must be greater than 0")
        
        else
            changeset
        end
    end

    def validate_occurance_hours(changeset), do: changeset
end