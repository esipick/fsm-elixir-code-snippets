defmodule Flight.Scheduling.Aircraft do
  use Ecto.Schema
  import Ecto.Changeset

  schema "aircrafts" do
    field(:ifr_certified, :boolean, default: false)
    field(:last_tach_time, Flight.HourTenth, default: 0)
    field(:last_hobbs_time, Flight.HourTenth, default: 0)
    field(:make, :string)
    field(:model, :string)
    field(:block_rate_per_hour, Flight.DollarCents)
    field(:rate_per_hour, Flight.DollarCents)
    field(:serial_number, :string)
    field(:equipment, :string)
    field(:simulator, :boolean, default: false)
    field(:tail_number, :string)
    field(:archived, :boolean, default: false)
    belongs_to(:school, Flight.Accounts.School)
    has_many(:inspections, Flight.Scheduling.Inspection)

    many_to_many(:users, Flight.Accounts.User, join_through: "user_aircrafts", on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(aircraft, attrs) do
    aircraft
    |> cast(attrs, [
      :make,
      :model,
      :tail_number,
      :serial_number,
      :ifr_certified,
      :simulator,
      :equipment,
      :last_tach_time,
      :last_hobbs_time,
      :rate_per_hour,
      :block_rate_per_hour
    ])
    |> validate_required([
      :ifr_certified,
      :simulator,
      :last_tach_time,
      :last_hobbs_time,
      :school_id
    ])
    |> validate_required([
      :make,
      :model,
      :tail_number,
      :serial_number,
      :equipment,
      :rate_per_hour,
      :block_rate_per_hour
    ])
    |> validate_number(:rate_per_hour, greater_than_or_equal_to: 0)
    |> validate_number(:block_rate_per_hour, greater_than_or_equal_to: 0)
    |> validate_format(
      :serial_number,
      Flight.Format.serial_number_regex(),
      message: "must be in a valid format"
    )
    |> validate_format(
      :tail_number,
      Flight.Format.tail_number_regex(),
      message: "must be in a valid format. (e.g. N55555)"
    )
  end

  def admin_changeset(aircraft, attrs) do
    changeset(aircraft, attrs)
  end

  def archive_changeset(aircraft, attrs) do
    aircraft
    |> cast(attrs, [:archived])
  end

  def archive(%Flight.Scheduling.Aircraft{} = aircraft) do
    aircraft
    |> change(archived: true)
    |> Flight.Repo.update()
  end
end
