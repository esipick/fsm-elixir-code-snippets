defmodule Flight.Repo.Migrations.AddAcceptedAtToInivitations do
  use Ecto.Migration

  def change do
    alter table(:invitations) do
      add(:accepted_at, :naive_datetime)
    end
  end
end
