defmodule Flight.Repo.Migrations.AddPaymentOptionToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:payment_option, :integer)
    end
  end
end
