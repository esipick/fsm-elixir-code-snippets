defmodule Flight.Scheduling.Appointment do
  use Ecto.Schema

  import Ecto.Changeset
  alias Flight.Scheduling

  schema "appointments" do
    field(:end_at, :naive_datetime)
    field(:start_at, :naive_datetime)
    field(:note, :string)
    field(:type, :string, default: "lesson")
    field(:status, InvoiceStatusEnum, default: :pending)
    field(:archived, :boolean, default: false)
    belongs_to(:school, Flight.Accounts.School)
    belongs_to(:instructor_user, Flight.Accounts.User)
    belongs_to(:user, Flight.Accounts.User)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)
    belongs_to(:transaction, Flight.Billing.Transaction)

    timestamps()
  end

  def __test_changeset(appointment, attrs, timezone) do
    appointment
    |> cast(attrs, [
      :start_at,
      :end_at,
      :user_id,
      :instructor_user_id,
      :aircraft_id,
      :note,
      :type,
      :status
    ])
    |> validate_required([
      :start_at,
      :end_at,
      :user_id,
      :school_id,
      :type
    ])
    |> apply_utc_timezone_changeset(timezone)
    |> validate_end_at_after_start_at
    |> validate_user_instructor_different
    |> validate_either_instructor_or_aircraft_set
  end

  @doc false
  def changeset(appointment, attrs, timezone) do
    appointment
    |> cast(attrs, [
      :start_at,
      :end_at,
      :user_id,
      :instructor_user_id,
      :aircraft_id,
      :note,
      :type,
      :status
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
    |> validate_either_instructor_or_aircraft_set
  end

  def update_transaction_changeset(appointment, attrs),
    do: cast(appointment, attrs, [:transaction_id])

  def allowed_for_archive?(appointment, user),
    do:
      !(Flight.Accounts.has_role?(user, "student") &&
          (is_paid?(appointment) ||
             is_ended?(appointment)))

  def paid(%Flight.Scheduling.Appointment{} = appointment),
    do: change(appointment, status: :paid) |> Flight.Repo.update()

  def archive(%Flight.Scheduling.Appointment{} = appointment),
    do: change(appointment, archived: true) |> Flight.Repo.update()

  defp is_paid?(appointment), do: appointment.status == :paid

  defp is_ended?(appointment),
    do: NaiveDateTime.compare(NaiveDateTime.utc_now(), appointment.end_at) == :gt

  defp apply_utc_timezone_changeset(changeset, timezone) do
    changeset
    |> Scheduling.apply_utc_timezone(:start_at, timezone)
    |> Scheduling.apply_utc_timezone(:end_at, timezone)
  end

  defp validate_either_instructor_or_aircraft_set(changeset) do
    if get_field(changeset, :instructor_user_id) || get_field(changeset, :aircraft_id) do
      changeset
    else
      add_error(changeset, :aircraft, "or instructor must be set.")
    end
  end

  defp validate_user_instructor_different(changeset) do
    with user_id <- get_field(changeset, :user_id),
         true <- user_id == get_field(changeset, :instructor_user_id) do
      add_error(changeset, :instructor, "cannot be the same person as the renter.")
    else
      _ -> changeset
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

  defp required_error_message(changeset, field, new_key, new_error_message) do
    update_in(
      changeset.errors,
      &Enum.map(&1, fn
        {key, {"can't be blank", validations}} when key == field ->
          {new_key, {new_error_message, validations}}

        {_key, _error} = tuple ->
          tuple
      end)
    )
  end
end
