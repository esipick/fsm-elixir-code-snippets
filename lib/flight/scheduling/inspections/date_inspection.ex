defmodule Flight.Scheduling.DateInspection do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:expiration, Flight.Date)
    field(:aircraft_id, :integer)
  end

  def changeset(date_inspection, attrs) do
    date_inspection
    |> cast(attrs, [:expiration, :aircraft_id, :name])
    |> validate_required([:aircraft_id, :name])
  end

  def attrs(date_inspection) do
    %{
      name: date_inspection.name,
      aircraft_id: date_inspection.aircraft_id,
      type: "date",
      date_value: date_inspection.expiration
    }
  end

  def new_changeset() do
    changeset(%Flight.Scheduling.DateInspection{}, %{})
  end
end
