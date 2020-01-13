defmodule Flight.Scheduling.Appointment do
  use Ecto.Schema
  import Ecto.Changeset

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

  @doc false
  def changeset(appointment, attrs) do
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
    |> validate_end_at_after_start_at()
    |> validate_user_instructor_different()
    |> validate_either_instructor_or_aircraft_set()
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

  def update_transaction_changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:transaction_id])
  end

  def validate_user_instructor_different(changeset) do
    user_id = get_field(changeset, :user_id)

    if user_id && user_id == get_field(changeset, :instructor_user_id) do
      add_error(changeset, :instructor, "cannot be the same person as the renter.")
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

  def validate_either_instructor_or_aircraft_set(changeset) do
    if get_field(changeset, :instructor_user_id) || get_field(changeset, :aircraft_id) do
      changeset
    else
      add_error(changeset, :aircraft, "or instructor must be set.")
    end
  end

  def paid(%Flight.Scheduling.Appointment{} = appointment) do
    change(appointment, status: :paid) |> Flight.Repo.update()
  end

  def archive(%Flight.Scheduling.Appointment{} = appointment) do
    change(appointment, archived: true) |> Flight.Repo.update()
  end
end
