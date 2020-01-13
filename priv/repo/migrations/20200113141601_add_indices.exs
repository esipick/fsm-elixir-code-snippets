defmodule Flight.Repo.Migrations.AddIndices do
  use Ecto.Migration

  def change do
    create(index(:invoices, [:school_id]))
    create(index(:invitations, [:user_id]))
    create(index(:invoices, [:archived]))
    create(index(:appointments, [:archived]))
    create(index(:appointments, [:status]))
  end
end
