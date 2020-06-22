defmodule Flight.Scheduling.Unavailability do
  use Ecto.Schema

  import Ecto.Changeset
  alias Flight.Scheduling

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

  def __test_changeset(unavailability, attrs, timezone) do
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
    |> apply_utc_timezone_changeset(timezone)
    |> validate_inclusion(:type, ["time_off"])
    |> validate_resources
  end

  @doc false
  def changeset(unavailability, attrs, timezone) do
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
    |> apply_utc_timezone_changeset(timezone)
    |> validate_end_at_after_start_at
    |> validate_inclusion(:type, ["time_off"])
    |> validate_resources
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
      {nil, _, "Instructor"} -> add_error(changeset, :instructor, "is required.")
      {_, nil, "Aircraft"} -> add_error(changeset, :aircraft, "is required.")
    end
  end

  defp apply_utc_timezone_changeset(changeset, timezone) do
    changeset
    |> Scheduling.apply_utc_timezone(:start_at, timezone)
    |> Scheduling.apply_utc_timezone(:end_at, timezone)
  end

  defp validate_end_at_after_start_at(changeset) do
    if changeset.valid? and
         NaiveDateTime.compare(get_field(changeset, :end_at), get_field(changeset, :start_at)) !=
           :gt do
      add_error(changeset, :end_at, "must come after start time.")
    else
      changeset
    end
  end
end
