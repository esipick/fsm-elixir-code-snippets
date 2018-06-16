defmodule Flight.Repo.Migrations.AddCompletedAtToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:completed_at, :naive_datetime)
    end
  end
end
