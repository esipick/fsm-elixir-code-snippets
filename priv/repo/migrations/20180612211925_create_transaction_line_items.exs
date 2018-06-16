defmodule Flight.Repo.Migrations.CreateTransactionLineItems do
  use Ecto.Migration

  def change do
    create table(:transaction_line_items) do
      add :amount, :integer
      add :description, :string
      add :transaction_id, references(:transactions, on_delete: :nothing)
      add :aircraft_id, references(:aircrafts, on_delete: :nothing)
      add :instructor_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:transaction_line_items, [:transaction_id])
    create index(:transaction_line_items, [:aircraft_id])
    create index(:transaction_line_items, [:instructor_user_id])
  end
end
