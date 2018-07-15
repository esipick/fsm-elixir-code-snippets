defmodule Flight.Repo.Migrations.AddContactEmailToSchool do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add(:contact_email, :string)
    end
  end
end
