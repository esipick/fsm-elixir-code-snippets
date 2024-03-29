defmodule Fsm.Aircrafts.Aircraft do
  use Ecto.Schema
  import Ecto.Changeset
  import ValidationUtil

  alias Flight.Inspections.{
    Maintenance,
    AircraftMaintenance
  }


  schema "aircrafts" do
    field(:ifr_certified, :boolean, default: false)
    field(:last_tach_time, Flight.HourTenth, default: 0)
    field(:last_hobbs_time, Flight.HourTenth, default: 0)
    field(:name, :string)
    field(:make, :string)
    field(:model, :string)
    field(:block_rate_per_hour, Flight.DollarCents)
    field(:rate_per_hour, Flight.DollarCents)
    field(:serial_number, :string)
    field(:equipment, :string)
    field(:simulator, :boolean, default: false)
    field(:tail_number, :string)
    field(:archived, :boolean, default: false)
    field(:blocked, :boolean, default: false)
    field(:airworthiness_certificate, :boolean, default: false)
    field(:registration_certificate_expires_at, Flight.Date)
    field(:insurance_expires_at, Flight.Date)
    field(:days_before, :integer, default: 30)
    field(:tach_hours_before, :integer, default: 200)
    belongs_to(:school, Flight.Accounts.School)
    has_many(:squawks, Fsm.Squawks.Squawk)
    has_many(:inspections, Fsm.Aircrafts.Inspection)
    has_many(:engines, Fsm.Aircrafts.Engine)
    has_many(:audit_logs, Flight.Logs.AuditLog)

    many_to_many(:maintenance, Maintenance, join_through: AircraftMaintenance)

    timestamps()
  end

  def fields_to_cast, do: ~w(make model tail_number serial_number ifr_certified simulator equipment last_tach_time
  last_hobbs_time rate_per_hour block_rate_per_hour name blocked airworthiness_certificate
  registration_certificate_expires_at insurance_expires_at days_before tach_hours_before)a

  @doc false
  def changeset(aircraft, attrs) do
    IO.inspect(attrs, label: "Aircraft Attrs:")
    aircraft
    |> cast(attrs, fields_to_cast())
    |> validate_required([
      :ifr_certified,
      :simulator,
      :last_tach_time,
      :last_hobbs_time,
      :school_id,
      :make,
      :model,
      :serial_number,
      :equipment,
      :rate_per_hour,
      :block_rate_per_hour
    ])
    |> validate_required_if(:name, :simulator)
    |> validate_required_unless(:tail_number, :simulator)
    |> validate_number(:rate_per_hour, greater_than_or_equal_to: 0, less_than: 2147483600, message: "(Rate per hour) must be between $0 and $21474835")
    |> validate_number(:block_rate_per_hour, greater_than_or_equal_to: 0, less_than: 2147483600, message: "(Block rate per hour) must be between $0 and $21474835")
#    |> validate_format(
#      :serial_number,
#      Flight.Format.serial_number_regex(),
#      message: "must be in a valid format"
#    )
#    |> validate_format(
#      :tail_number,
#      Flight.Format.tail_number_regex(),
#      message: "must be in a valid format. (e.g. N55555)"
#    )
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

  def display_name(aircraft \\ nil) do
    if aircraft && aircraft.simulator do
      "Simulator"
    else
      "Aircraft"
    end
  end
end
