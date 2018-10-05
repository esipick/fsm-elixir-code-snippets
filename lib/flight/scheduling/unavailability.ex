defmodule Flight.Scheduling.Unavailability do
  use Ecto.Schema
  import Ecto.Changeset

  schema "unavailabilities" do
    field(:available, :boolean, default: false)
    field(:type, :string, default: "time_off")
    field(:note, :string)
    field(:end_at, :naive_datetime)
    field(:start_at, :naive_datetime)
    belongs_to(:school, Flight.Accounts.School)
    belongs_to(:instructor_user, Flight.Accounts.User)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)

    timestamps()
  end

  @doc false
  def changeset(unavailability, attrs) do
    unavailability
    |> cast(attrs, [
      :start_at,
      :end_at,
      :available,
      :type,
      :note,
      :instructor_user_id,
      :aircraft_id
    ])
    |> validate_required([:start_at, :end_at, :available, :type, :school_id])
    |> validate_inclusion(:type, ["time_off"])
    |> validate_resources()
  end

  def validate_resources(changeset) do
    instructor_user_id = get_field(changeset, :instructor_user_id)
    aircraft_id = get_field(changeset, :aircraft_id)

    case {instructor_user_id, aircraft_id} do
      {x, y} when is_nil(x) and is_integer(y) -> changeset
      {x, y} when is_integer(x) and is_nil(y) -> changeset
      _ -> add_error(changeset, :aircraft, "cannot be assigned if instructor is also assigned")
    end
  end

  def apply_timezone_changeset(changeset, timezone) do
    changeset
    |> apply_timezone(:start_at, timezone)
    |> apply_timezone(:end_at, timezone)
  end

  def apply_timezone(changeset, key, timezone) do
    change = get_field(changeset, key)

    if change do
      put_change(changeset, key, Flight.Walltime.utc_to_walltime(change, timezone))
    else
      changeset
    end
  end
end
