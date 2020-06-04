defmodule Flight.Repo.Migrations.AddTitleToDocuments do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add(:title, :string)
    end
  end
end
