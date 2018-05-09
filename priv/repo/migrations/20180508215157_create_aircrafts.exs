defmodule Flight.Repo.Migrations.CreateAircrafts do
  use Ecto.Migration

  def change do
    create table(:aircrafts) do
      add(:make, :string)
      add(:model, :string)
      add(:tail_number, :string)
      add(:serial_number, :string)
      add(:equipment, :string)
      add(:ifr_certified, :boolean, default: false, null: false)
      add(:simulator, :boolean, default: false, null: false)
      add(:last_tach_time, :integer)
      add(:rate_per_hour, :integer)
      add(:block_rate_per_hour, :integer)

      timestamps()
    end
  end
end
