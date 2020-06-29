defmodule Flight.Repo.Migrations.CreateLatestIosAppVersions do
  use Ecto.Migration

  def change do
    create table(:ios_app_versions) do
      add(:version, :text, null: false)

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end
