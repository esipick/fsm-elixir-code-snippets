defmodule Flight.Repo.Migrations.AlterAppointmentsAddParentId do
  use Ecto.Migration

  def up do
    alter table(:appointments) do
      add(:parent_id, :integer)
    end
  end

  def down do
    alter table(:appointments) do
      remove(:parent_id)
    end
  end
end
