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
      :archived,
      :block_rate_per_hour
    ])
    |> validate_required([
      :make,
      :model,
      :tail_number,
      :serial_number,
      :ifr_certified,
      :equipment,
      :simulator,
      :last_tach_time,
      :last_hobbs_time,
      :rate_per_hour,
      :block_rate_per_hour,
      :school_id
    ])
  end

  def admin_changeset(aircraft, attrs) do
    changeset(aircraft, attrs)
  end

  def archive_changeset(user, attrs) do
    user
    |> cast(attrs, [:archived])
  end
end
