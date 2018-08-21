defmodule Flight.Repo.Migrations.AddTimezoneToSchool do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add(:timezone, :string)
    end
  end
end
