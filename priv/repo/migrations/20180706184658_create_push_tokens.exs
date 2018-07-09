defmodule Flight.Repo.Migrations.CreatePushTokens do
  use Ecto.Migration

  def change do
    create table(:push_tokens) do
      add(:endpoint_arn, :string)
      add(:token, :string)
      add(:platform, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:push_tokens, [:user_id]))
    create(unique_index(:push_tokens, [:platform, :token]))
  end
end
