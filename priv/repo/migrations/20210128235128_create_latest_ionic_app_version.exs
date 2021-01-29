defmodule Flight.Repo.Migrations.CreateLatestIonicAppVersion do
  use Ecto.Migration

  def change do
    create table(:ionic_app_versions) do
      add(:version, :text, null: false)
      add(:int_version, :integer, null: false)

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end
