defmodule Flight.Repo.Migrations.AddPilotProfileFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:pilot_current_certificate, {:array, :string}, default: [], null: false)
      add(:pilot_aircraft_categories, {:array, :string}, default: [], null: false)
      add(:pilot_class, {:array, :string}, default: [], null: false)
      add(:pilot_ratings, {:array, :string}, default: [], null: false)
      add(:pilot_endorsements, {:array, :string}, default: [], null: false)
      add(:pilot_certificate_number, :string)
      add(:pilot_certificate_expires_at, :date)
    end
  end
end
