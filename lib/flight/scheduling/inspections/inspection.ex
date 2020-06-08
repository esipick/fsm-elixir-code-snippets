defmodule Flight.Scheduling.Inspection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inspections" do
    field(:name, :string)
    field(:type, :string)
    field(:date_value, Flight.Date)
    field(:number_value, :integer)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)

    timestamps()
  end

  @doc false
  def changeset(inspection, attrs) do
    inspection
    |> cast(attrs, [:type, :date_value, :number_value, :aircraft_id, :name])
    |> validate_required([:type, :name, :aircraft_id])
    |> validate_inclusion(:type, ["date", "tach"])
    |> validate_by_type()
  end

  def validate_by_type(changeset) do
    validate_by_type(changeset, get_field(changeset, :type))
  end

  def validate_by_type(changeset, type) do
    case type do
      "date" -> date_validations(changeset)
      "tach" -> tach_validations(changeset)
      _ -> raise "Unknown inspection type attempting validation: #{type}"
    end
  end

  def date_validations(changeset) do
    changeset
    |> validate_number_nil()
  end

  def tach_validations(changeset) do
    changeset
    |> validate_date_nil()
  end

  def validate_number_nil(changeset) do
    if get_field(changeset, :number_value) do
      add_error(changeset, :number_value, "must be nil")
    else
      changeset
    end
  end

  def validate_date_nil(changeset) do
    if get_field(changeset, :date_value) do
      add_error(changeset, :date_value, "must be nil")
    else
      changeset
    end
  end

  def to_specific(inspection) do
    case inspection.type do
      "date" ->
        %Flight.Scheduling.DateInspection{
          name: inspection.name,
          expiration: inspection.date_value,
          aircraft_id: inspection.aircraft_id,
          id: inspection.id
        }

      "tach" ->
        %Flight.Scheduling.TachInspection{
          name: inspection.name,
          tach_time: inspection.number_value,
          aircraft_id: inspection.aircraft_id,
          id: inspection.id
        }
    end
  end
end
