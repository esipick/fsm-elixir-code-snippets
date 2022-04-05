defmodule Flight.Scheduling.Appointment do
  use Ecto.Schema

  import Ecto.Changeset
  alias Flight.Scheduling
  alias Flight.SchoolAssets.Room

  schema "appointments" do
    field(:end_at, :naive_datetime)
    field(:start_at, :naive_datetime)
    field(:note, :string)
    field(:payer_name, :string)
    field(:demo, :boolean, default: false)
    field(:type, :string, default: "none")
    field(:status, InvoiceStatusEnum, default: :pending)
    field(:archived, :boolean, default: false)

    field(:start_tach_time, Flight.HourTenth, null: true)
    field(:end_tach_time, Flight.HourTenth, null: true)

    field(:start_hobbs_time, Flight.HourTenth, null: true)
    field(:end_hobbs_time, Flight.HourTenth, null: true)

    field(:simulator_id, :integer)
    field(:room_id, :integer)

    field(:inst_start_at, :naive_datetime)
    field(:inst_end_at, :naive_datetime)
    field(:appt_status, CheckRideStatus, default: :none)
    field(:parent_id, :integer)

    belongs_to(:school, Flight.Accounts.School)
    belongs_to(:instructor_user, Flight.Accounts.User)
    belongs_to(:mechanic_user, Flight.Accounts.User)
    belongs_to(:owner_user, Flight.Accounts.User)
    belongs_to(:user, Flight.Accounts.User)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)
    belongs_to(:transaction, Flight.Billing.Transaction)
    belongs_to(:simulator, Flight.Scheduling.Aircraft, foreign_key: :simulator_id, references: :id, define_field: false)
    belongs_to(:room, Room, define_field: false)

    timestamps()
  end

  def types(), do: ["airplane_rental", "demo_flight", "check_ride", "flight_lesson", "unavailable", "meeting", "maintenance"]
  def instructor_times(), do: [{"None", 0}, {"30 minutes", 1800}, {"1 hour", 3600}, {"1 h 30 min", 5400}, {"2 hours", 7200}]

  def __test_changeset(appointment, attrs, timezone) do
    appointment
    |> cast(attrs, [
      :start_at,
      :end_at,
      :user_id,
      :instructor_user_id,
      :mechanic_user_id,
      :owner_user_id,
      :aircraft_id,
      :note,
      :payer_name,
      :demo,
      :type,
      :status,
      :inst_start_at,
      :inst_end_at,
      :appt_status
    ])
    |> validate_required([
      :start_at,
      :end_at,
      :school_id,
      :type
    ])
    |> apply_utc_timezone_changeset(timezone)
    |> validate_end_at_after_start_at
    |> validate_user_instructor_different
    |> validate_instructor_and_resource_set
    |> validate_demo_aircraft_set
  end

  @doc false
  def changeset(appointment, attrs, _timezone) do
    appointment
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required([
      :start_at,
      :end_at,
      :school_id,
      :type
    ])
    |> normalize_type
    |> validate_inclusion(:type, types())
    |> check_demo_flight
    |> validate_end_at_after_start_at
    |> validate_user_instructor_different
    |> validate_instructor_and_resource_set
    |> validate_demo_aircraft_set
    |> validate_assets
    |> normalize_instructor_times
  end

  def update_transaction_changeset(appointment, attrs),
    do: cast(appointment, attrs, [:transaction_id])

  def paid(%Flight.Scheduling.Appointment{} = appointment),
    do: change(appointment, status: :paid) |> Flight.Repo.update()

  def archive(%Flight.Scheduling.Appointment{} = appointment),
    do: change(appointment, archived: true) |> Flight.Repo.update()

  def is_paid?(appointment), do: appointment.status == :paid

  defp apply_utc_timezone_changeset(changeset, timezone) do
    changeset
    |> Scheduling.apply_utc_timezone(:start_at, timezone)
    |> Scheduling.apply_utc_timezone(:end_at, timezone)
  end

  def normalize_type(%Ecto.Changeset{valid?: true, changes: %{type: type}} = changeset) do
    type = type || "none"
    type =
        type
        |> String.downcase

    put_change(changeset, :type, type)
  end
  def normalize_type(changeset), do: changeset

  def check_demo_flight(%Ecto.Changeset{valid?: true, changes: %{type: "demo_flight"}} = changeset) do
    put_change(changeset, :demo, true)
  end
  def check_demo_flight(changeset), do: changeset

  defp validate_instructor_and_resource_set(changeset) do
    cond do
      get_field(changeset, :demo) ->
        changeset

      get_field(changeset, :type) == "maintenance" ->
        if (get_field(changeset, :aircraft_id) == nil or get_field(changeset, :mechanic_user_id) == nil) do
          add_error(changeset, :aircraft, "and mechanic is required.")
        else
          changeset
        end

      get_field(changeset, :type) == "flight_lesson" and
      ( get_field(changeset, :simulator_id) != nil or get_field(changeset, :room_id) != nil) ->
        changeset

      get_field(changeset, :type) == "flight_lesson" and
      ( get_field(changeset, :aircraft_id) == nil and
        get_field(changeset, :simulator_id) == nil and get_field(changeset, :room_id) == nil) ->

        add_error(changeset, :resource, "(aircraft or simulator or room) is required.")

      (get_field(changeset, :instructor_user_id) && get_field(changeset, :aircraft_id)) ||
      get_field(changeset, :type) != "meeting" && (get_field(changeset, :simulator_id) || get_field(changeset, :room_id)) ->
        changeset

      get_field(changeset, :type) == "flight_lesson" and get_field(changeset, :instructor_user_id) == nil->
        add_error(changeset, :instructor, "is required.")

      get_field(changeset, :type) == "flight_lesson" and get_field(changeset, :aircraft_id) == nil->
        add_error(changeset, :aircraft, "is required.")

      (get_field(changeset, :type) == "airplane_rental" or get_field(changeset, :type) == "check_ride") ->
        if get_field(changeset, :aircraft_id) == nil do
          add_error(changeset, :aircraft, "is required.")
        else
          changeset
        end

      get_field(changeset, :type) == "meeting" ->
        if get_field(changeset, :room_id) == nil || get_field(changeset, :instructor_user_id) == nil do
          add_error(changeset, :room, "and instructor is required.")
        else
          changeset
        end

      true ->
        add_error(changeset, :aircraft, "or instructor is required.")
    end
  end

  defp validate_demo_aircraft_set(changeset) do
    cond do
      !get_field(changeset, :demo) -> changeset
      get_field(changeset, :aircraft_id) -> changeset
      true -> add_error(changeset, :aircraft, "is required for demo flights.")
    end
  end

  defp normalize_instructor_times(changeset) do
    if changeset.valid? do
      inst_id = get_field(changeset, :instructor_user_id)

      start_at = get_field(changeset, :start_at)
      end_at = get_field(changeset, :end_at)

      inst_started_at = get_field(changeset, :inst_start_at)
      inst_ended_at = get_field(changeset, :inst_end_at)

      # if appointment has instructor,
      # inst_start_at should be non nil otherwise it should be nil.
      {inst_started_at, inst_ended_at} =
        if !is_nil(inst_id) do
          inst_started_at = inst_started_at || start_at
          inst_ended_at = inst_ended_at || end_at
          {inst_started_at, inst_ended_at}
        else
          {nil, nil}
        end

      changeset
      |> put_change(:inst_start_at, inst_started_at)
      |> put_change(:inst_end_at, inst_ended_at)

    else
      changeset
    end
  end

  defp validate_user_instructor_different(changeset) do
    cond do
      get_field(changeset, :demo) ->
        changeset

      get_field(changeset, :type) == "maintenance" ->
        changeset

      get_field(changeset, :instructor_user_id) || get_field(changeset, :user_id) ->
        with user_id <- get_field(changeset, :user_id),
             true <- user_id == get_field(changeset, :instructor_user_id) do
          add_error(changeset, :instructor, "cannot be the same person as the renter.")
        else
          _ ->
            cond do
              get_field(changeset, :type) == "flight_lesson" and get_field(changeset, :aircraft_id) != nil and get_field(changeset, :user_id) == nil ->
                add_error(changeset, :pilot, "is required.")

              (get_field(changeset, :type) == "flight_lesson" or get_field(changeset, :type) == "airplane_rental" or get_field(changeset, :type) == "check_ride" or get_field(changeset, :type) == "meeting") and get_field(changeset, :user_id) == nil ->
                add_error(changeset, :pilot, "is required.")

              true ->
                changeset
            end
        end

      (get_field(changeset, :type) == "flight_lesson" or get_field(changeset, :type) == "airplane_rental" or get_field(changeset, :type) == "check_ride" or get_field(changeset, :type) == "meeting") and get_field(changeset, :user_id) == nil ->
          add_error(changeset, :pilot, "is required.")

      true ->
        add_error(changeset, :instructor, "or pilot is required.")
    end
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

  defp validate_assets(changeset) do

    {changeset, aircraft_id, simulator_id, room_id} =
      cond do
        get_field(changeset, :type) == "maintenance" ->
          changeset = put_change(changeset, :room_id, nil)
          changeset = put_change(changeset, :simulator_id, nil)
          {changeset, get_field(changeset, :aircraft_id) || get_change(changeset, :aircraft_id), get_change(changeset, :simulator_id), get_change(changeset, :room_id)}

        get_field(changeset, :type) == "meeting" ->
          changeset = put_change(changeset, :aircraft_id, nil)
          changeset = put_change(changeset, :simulator_id, nil)
          changeset = put_change(changeset, :mechanic_user_id, nil)
          {changeset, get_change(changeset, :aircraft_id), get_change(changeset, :simulator_id), get_change(changeset, :room_id)}

        true ->
          changeset = put_change(changeset, :mechanic_user_id, nil)
        {changeset, get_field(changeset, :aircraft_id) || get_change(changeset, :aircraft_id), get_field(changeset, :simulator_id) || get_change(changeset, :simulator_id), get_field(changeset, :room_id) || get_change(changeset, :room_id)}
      end

    cond do
      aircraft_id && simulator_id && room_id ->
        add_error(changeset, :aircraft, " , Simulator and Room cannot be scheduled at a time.")
      aircraft_id && simulator_id -> add_error(changeset, :aircraft, " and Simulator cannot be scheduled at a time.")
      aircraft_id && room_id -> add_error(changeset, :aircraft, " and Room cannot be scheduled at a time.")
      simulator_id && room_id -> add_error(changeset, :simulator, " and Room cannot be scheduled at a time.")
      true -> changeset
    end
  end
end
