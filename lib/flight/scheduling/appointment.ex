defmodule Flight.Scheduling.Appointment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appointments" do
    field(:end_at, :naive_datetime)
    field(:start_at, :naive_datetime)
    belongs_to(:instructor_user, Flight.Accounts.User)
    belongs_to(:user, Flight.Accounts.User)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)
    belongs_to(:transaction, Flight.Billing.Transaction)

    timestamps()
  end

  @doc false
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:start_at, :end_at, :user_id, :instructor_user_id, :aircraft_id])
    |> validate_required([:start_at, :end_at, :user_id])
    |> validate_end_at_after_start_at()
    |> validate_user_instructor_different()
    |> validate_either_instructor_or_aircraft_set()
  end

  def update_transaction_changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:transaction_id])
    |> validate_required([:transaction_id])
  end

  def validate_user_instructor_different(changeset) do
    if get_field(changeset, :user_id) == get_field(changeset, :instructor_user_id) do
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
        add_error(changeset, :end_at, "must come after start_at.")
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
end
