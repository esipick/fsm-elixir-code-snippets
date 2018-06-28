defmodule Flight.Repo.Migrations.AddNoteToAppointment do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add(:note, :string)
    end
  end
end
