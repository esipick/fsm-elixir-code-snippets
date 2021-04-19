defmodule Flight.Repo.Migrations.AddAndroidAndIosVersionsToIonicAppVersion do
  use Ecto.Migration

  def up do
    alter table(:ionic_app_versions) do
      add(:android_version, :text, null: false, default: "4.0.28")
      add(:android_int_version, :integer, null: false, default: 4000028)
      add(:ios_version, :text, null: false, default: "4.0.28")
      add(:ios_int_version, :integer, null: false, default: 4000028)
    end
  end

  def down do
    alter table(:ionic_app_versions) do
      remove(:android_version)
      remove(:android_int_version)
      remove(:ios_version)
      remove(:ios_int_version)
    end
  end
end
