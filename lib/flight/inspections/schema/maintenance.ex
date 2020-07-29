defmodule Flight.Inspections.Maintenance do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Scheduling.Aircraft
    alias Flight.Inspections.{
        CheckList,
        Maintenance,
        AircraftMaintenance,
        MaintenanceCheckList
    }

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "maintenance" do
        field(:name, :string, null: false)
        field(:description, :string, null: true)
        
        field(:tach_hours, :integer, null: true) # the event will occur after this many tach hours
        field(:no_of_months, :integer, null: true) # Or the event will occur in this many days

        field(:ref_start_date, :naive_datetime, null: true) # ref date to start counting no_of_months to the maintenance.
        field(:due_date, :naive_datetime, null: true)

        many_to_many(:checklists, CheckList, join_through: MaintenanceCheckList, join_keys: [maintenance_id: :id, checklist_id: :id])
        many_to_many(:aircrafts, Aircraft, join_through: AircraftMaintenance)

        timestamps([inserted_at: :created_at])
    end

    def required_fields(), do: ~w(name)a

    def changeset(%Maintenance{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(__MODULE__.required_fields)
        |> validate_occurance_hours
        |> unique_constraint(:name, message: "Maintenance with the same name already exists.")
    end

    def validate_occurance_hours(%Ecto.Changeset{valid?: true} = changeset) do
        tach_hours = get_change(changeset, :tach_hours) || get_field(changeset, :tach_hours) || 0
        days = get_change(changeset, :no_of_months) || get_field(changeset, :no_of_months) || 0
        ref_date = get_field(changeset, :ref_start_date) || NaiveDateTime.truncate(NaiveDateTime.utc_now, :second)
        
        cond do
            tach_hours <= 0 && days <= 0 ->
                changeset
                |> add_error(:tach_hours, "Must be greater than 0 value.")
                |> add_error(:no_of_days, "Must be greater than 0 value.")

            tach_hours > 0 && days > 0 ->
                changeset
                |> add_error(:tach_hours, "Schedule based on tach hours or calendar months please.")

            days > 0 -> 
                changeset
                |> put_change(:ref_start_date, ref_date)
                |> put_change(:due_date, Flight.Utils.add_months(ref_date, days)) # expected due date, write utils to add this many days to now.
                |> put_change(:tach_hours, nil)

            tach_hours > 0 ->
                changeset
                |> put_change(:no_of_months, nil)

            true -> changeset
        end
    end

    def validate_occurance_hours(changeset), do: changeset
end