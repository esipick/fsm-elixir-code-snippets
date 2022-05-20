defmodule Flight.Repo.Migrations.AlterAircraftsAddAirworthinessFields do
  use Ecto.Migration

  def change do
    alter table(:aircrafts) do
      add(:airworthiness_certificate, :boolean, default: false, null: false)
      add(:registration_certificate_expires_at, :date)
      add(:insurance_expires_at, :date)
    end
  end
end
