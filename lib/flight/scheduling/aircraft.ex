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
      :block_rate_per_hour
    ])
    |> validate_required([
      :ifr_certified,
      :simulator,
      :last_tach_time,
      :last_hobbs_time,
      :school_id
    ])
    |> validate_required(:make, message: "Make can't be blank")
    |> validate_required(:model, message: "Model can't be blank")
    |> validate_required(:tail_number, message: "Tail number can't be blank")
    |> validate_required(:serial_number, message: "Serial number can't be blank")
    |> validate_required(:equipment, message: "Equipment can't be blank")
    |> validate_required(:rate_per_hour, message: "RPH can't be blank")
    |> validate_required(:block_rate_per_hour, message: "BRPH can't be blank")
  end

  def admin_changeset(aircraft, attrs) do
    changeset(aircraft, attrs)
  end

  def archive_changeset(user, attrs) do
    user
    |> cast(attrs, [:archived])
  end
end
