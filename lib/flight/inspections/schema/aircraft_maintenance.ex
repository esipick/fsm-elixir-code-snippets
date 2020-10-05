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

        field(:start_tach_hours, :integer) # at this tach time, the event is gonna start.
        field(:due_tach_hours, :integer) # at this tach time, the event is due.

        field(:start_date, :naive_datetime, null: true)
        field(:due_date, :naive_datetime, null: true)

        field(:start_et, :naive_datetime, null: true)
        field(:end_et, :naive_datetime, null: true)

        field(:status, :string, default: "pending")

        field(:duration, :integer, virtual: true)
        field(:current_tach_hours, :integer, virtual: true)

        belongs_to(:aircraft, Aircraft, define_field: false, foreign_key: :aircraft_id)
        belongs_to(:maintenance, Maintenance, define_field: false, foreign_key: :maintenance_id)

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(aircraft_id maintenance_id duration)a

    def changeset(%AircraftMaintenance{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields) ++ [:duration, :current_tach_hours])
        |> validate_required(required_fields())
        |> normalize_status
        |> validate_inclusion(:status, @allowed_status)
        |> calculate_start
        |> unique_constraint(:aircraft_maintenance, name: :one_pending_maintenance, message: "Maintenance Already assigned")
        |> foreign_key_constraint(:aircraft_id, name: :aircraft_maintenance_aircraft_id_fkey, message: "No aircraft with id: #{inspect Map.get(params, "aircraft_id")} found.")
    end

    def normalize_status(%Ecto.Changeset{valid?: true, changes: %{status: status}} = changeset) do
        status = status || "pending"
        status = 
            status
            |> String.downcase

        put_change(changeset, :status, status)
    end
    def normalize_status(changeset), do: changeset
 
    def calculate_start(%Ecto.Changeset{valid?: true} = changeset) do
        due_date = get_change(changeset, :due_date) 
        due_tach_hours = get_change(changeset, :due_tach_hours)
        duration = get_change(changeset, :duration)
        current_tach_hours = get_change(changeset, :current_tach_hours)

        cond do
            due_date != nil && duration > 0 -> 
                start_date = Flight.Utils.add_months(due_date, -duration)
                changeset
                |> put_change(:start_date, start_date)
                |> put_change(:start_tach_hours, nil)
                |> put_change(:due_tach_hours, nil)

            due_tach_hours != nil and duration > 0 ->
                condition = (current_tach_hours == nil) || (due_tach_hours > 0 && current_tach_hours < due_tach_hours)
                
                if (current_tach_hours == nil) || (due_tach_hours > 0 && due_tach_hours < current_tach_hours) do
                    add_error(changeset, :due_tach_hours, "due_tach_hours should be greater than current_tach_hours: #{current_tach_hours}.")
                else
                    changeset
                    |> put_change(:start_tach_hours, (due_tach_hours - duration))
                    |> put_change(:start_date, nil)
                    |> put_change(:due_date, nil)
                end

            true ->
                add_error(changeset, :due_tach_hours, "due_tach_hours or due_date is required.") 
        end
    end
    def calculate_start(changeset), do: changeset
end