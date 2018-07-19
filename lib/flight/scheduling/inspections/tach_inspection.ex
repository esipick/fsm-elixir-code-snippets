defmodule Flight.Scheduling.TachInspection do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:tach_time, Flight.HourTenth)
    field(:aircraft_id, :integer)
  end

  def changeset(tach_inspection, attrs) do
    tach_inspection
    |> cast(attrs, [:tach_time, :aircraft_id, :name])
    |> validate_required([:aircraft_id, :name])
  end

  def attrs(tach_inspection) do
    %{
      name: tach_inspection.name,
      aircraft_id: tach_inspection.aircraft_id,
      type: "tach",
      number_value: tach_inspection.tach_time
    }
  end

  def new_changeset() do
    changeset(%Flight.Scheduling.TachInspection{}, %{})
  end
end
