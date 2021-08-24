defmodule Flight.Repo.Migrations.AlterAppVersionsTable do
  use Ecto.Migration

  def change do
    rename table("ionic_app_versions"), to: table("app_versions")
    alter table(:app_versions) do
      add(:web_version, :string)
    end
  end
end
