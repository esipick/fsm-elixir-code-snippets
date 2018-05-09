defmodule Flight.Scheduling.Aircraft do
  use Ecto.Schema
  import Ecto.Changeset

  schema "aircrafts" do
    field(:block_rate_per_hour, :integer)
    field(:ifr_certified, :boolean, default: false)
    field(:last_tach_time, :integer)
    field(:make, :string)
    field(:model, :string)
    field(:rate_per_hour, :integer)
    field(:serial_number, :string)
    field(:equipment, :string)
    field(:simulator, :boolean, default: false)
    field(:tail_number, :string)

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
      :rate_per_hour,
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
      :rate_per_hour,
      :block_rate_per_hour
    ])
  end
end
