defmodule Flight.Scheduling.Unavailability do
  use Ecto.Schema

  import Ecto.Changeset
  alias Flight.Scheduling
  alias Flight.SchoolAssets.Room

  schema "unavailabilities" do
    field(:available, :boolean, default: false)
    field(:type, :string, default: "time_off")
    field(:note, :string)
    field(:end_at, :naive_datetime)
    field(:start_at, :naive_datetime)
    field(:belongs, :string)

    field(:simulator_id, :integer)
    field(:room_id, :integer)

    belongs_to(:school, Flight.Accounts.School)
    belongs_to(:instructor_user, Flight.Accounts.User)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)
    belongs_to(:simulator, Flight.Scheduling.Aircraft, foreign_key: :simulator_id, references: :id, define_field: false)
    belongs_to(:room, Room, define_field: false)

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
    |> apply_utc_timezone_changeset(attrs, timezone)
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
      :simulator_id,
      :room_id,
      :belongs
    ])
    |> validate_required([:start_at, :end_at, :available, :type, :school_id])
    |> apply_utc_timezone_changeset(attrs, timezone)
    |> validate_end_at_after_start_at
    |> validate_inclusion(:type, ["time_off"])
    |> validate_resources
  end

  def validate_resources(changeset) do
    instructor_user_id = get_field(changeset, :instructor_user_id)
    aircraft_id = get_field(changeset, :aircraft_id)
    simulator_id = get_field(changeset, :simulator_id)
    room_id = get_field(changeset, :room_id)

    belongs = get_field(changeset, :belongs)

    case {instructor_user_id, aircraft_id, simulator_id, room_id, belongs} do
      {_, y, _, _, "Aircraft"} when is_integer(y) -> changeset
      {x, _, _, _, "Instructor"} when is_integer(x) -> changeset
      {_, _, s, _, "Simulator"} when is_integer(s) -> changeset
      {_x, _, _, r, "Room"} when is_integer(r) -> changeset

      {_, y, _s, _r, nil} when is_integer(y) -> changeset
      {x, _, _s, _r, nil} when is_integer(x) -> changeset
      {nil, _, _, _, "Instructor"} -> add_error(changeset, :instructor, "is required.")
      {_, nil, _, _, "Aircraft"} -> add_error(changeset, :aircraft, "is required.")
      {_, _, nil, _, "Simulator"} -> add_error(changeset, :simulator, "is required.")
      {_, _, _, nil, "Room"} -> add_error(changeset, :room, "is required.")
    end
  end

  defp apply_utc_timezone_changeset(changeset, attrs, timezone) do
    changeset
    |> Scheduling.apply_utc_timezone_if_aircraft(attrs, "aircraft_id", timezone)
    |> Scheduling.apply_utc_timezone_if_aircraft(attrs, "room_id", timezone)
    |> Scheduling.apply_utc_timezone_if_aircraft(attrs, "simulator_id", timezone)
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
