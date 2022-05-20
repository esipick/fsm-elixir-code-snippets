defmodule Flight.Repo.Migrations.AlterAlertsAddArchivedField do
  use Ecto.Migration

  def up do
    alter table(:alerts) do
      add(:archived, :boolean, default: false)
    end
  end

  def down do
    alter table(:alerts) do
      remove(:archived)
    end
  end
end
