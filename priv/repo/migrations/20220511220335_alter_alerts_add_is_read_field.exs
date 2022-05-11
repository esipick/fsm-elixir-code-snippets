defmodule Flight.Repo.Migrations.AlterAlertsAddIsReadField do
  use Ecto.Migration

  def up do
    alter table(:alerts) do
      add(:is_read, :boolean, default: false)
    end
  end

  def down do
    alter table(:alerts) do
      remove(:is_read)
    end
  end
end
