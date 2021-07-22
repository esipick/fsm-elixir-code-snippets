defmodule Flight.Repo.Migrations.CreateTableInspections do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  def change do

    rename table("inspections"), to: table("old_inspections")

    DateTachEnum.create_type()
    create table(:inspections) do
      add(:name, :string)
      add(:type, :string)
      add(:updated, :boolean, default: false)
      add(:is_completed, :boolean, default: false)
      add(:note, :string)
      add(:is_repeated, :boolean)
      add(:repeat_every_days, :integer)
      add(:date_tach, DateTachEnum.type())
      add(:is_notified, :boolean, default: false)
      add(:is_email_notified, :boolean)
      add(:is_system_defined, :boolean)

      add(:completed_at, :naive_datetime)

      add(:aircraft_id, references(:aircrafts, on_delete: :nothing))
      add(:aircraft_engine_id, references(:aircraft_engines, on_delete: :nothing))

      soft_delete_columns()
      timestamps()
    end
  end
end
