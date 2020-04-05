defmodule Flight.Scheduling.Unavailability do
  use Ecto.Schema
  import Ecto.Changeset

  schema "unavailabilities" do
    field(:available, :boolean, default: false)
    field(:type, :string, default: "time_off")
    field(:note, :string)
    field(:end_at, :naive_datetime)
    field(:start_at, :naive_datetime)
    field(:belongs, :string)
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
      :aircraft_id,
      :belongs
    ])
    |> validate_required([:start_at, :end_at, :available, :type, :school_id])
    |> validate_end_at_after_start_at()
    |> validate_inclusion(:type, ["time_off"])
    |> validate_resources()
  end

  def validate_resources(changeset) do
    instructor_user_id = get_field(changeset, :instructor_user_id)
    aircraft_id = get_field(changeset, :aircraft_id)
    belongs = get_field(changeset, :belongs)

    case {instructor_user_id, aircraft_id, belongs} do
      {_, y, "Aircraft"} when is_integer(y) -> changeset
      {x, _, "Instructor"} when is_integer(x) -> changeset
      {_, y, nil} when is_integer(y) -> changeset
      {x, _, nil} when is_integer(x) -> changeset
      {nil, _, "Instructor"} -> add_error(changeset, :instructor, "must be set.")
      {_, nil, "Aircraft"} -> add_error(changeset, :aircraft, "must be set.")
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

  def validate_end_at_after_start_at(changeset) do
    if changeset.valid? do
      start_at = get_field(changeset, :start_at)
      end_at = get_field(changeset, :end_at)

      if NaiveDateTime.compare(end_at, start_at) == :gt do
        changeset
      else
        add_error(changeset, :end_at, "must come after start time.")
      end
    else
      changeset
    end
  end
end
