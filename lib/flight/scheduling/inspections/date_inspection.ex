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
    |> validate_required([:name, :expiration, :aircraft_id])
    |> validate_expiration_after_today()
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

  def validate_expiration_after_today(changeset) do
    if changeset.valid? do
      today = Date.utc_today()
      expiration = get_field(changeset, :expiration)

      if Date.compare(expiration, today) == :gt do
        changeset
      else
        add_error(changeset, :expiration, "should be future date")
      end
    else
      changeset
    end
  end
end
