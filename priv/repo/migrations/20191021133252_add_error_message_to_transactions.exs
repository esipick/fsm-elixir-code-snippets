defmodule Flight.Repo.Migrations.AddErrorMessageToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:error_message, :text)
    end
  end
end
