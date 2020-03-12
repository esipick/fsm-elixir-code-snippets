defmodule Flight.Repo.Migrations.AddBelongsToUnavailabilities do
  use Ecto.Migration

  def change do
    alter table(:unavailabilities) do
      add(:belongs, :string)
    end
  end
end
