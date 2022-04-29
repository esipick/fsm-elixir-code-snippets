defmodule Flight.Repo.Migrations.AlterAlertsMakeFieldsOptional do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE alerts DROP CONSTRAINT alerts_receiver_id_fkey"
    execute "ALTER TABLE alerts DROP CONSTRAINT alerts_sender_id_fkey"
    alter table(:alerts) do
      modify(:code, :string, null: true)
      modify(:title, :string, null: true)
      modify(:description, :string, null: true)

      modify(:priority, :integer, null: true)

      modify(:receiver_id, references(:users, type: :id, on_delete: :nothing), null: true)
      modify(:sender_id, references(:users, type: :id, on_delete: :nothing), null: true)
    end
  end


  def down do
    execute "ALTER TABLE alerts DROP CONSTRAINT alerts_receiver_id_fkey"
    execute "ALTER TABLE alerts DROP CONSTRAINT alerts_sender_id_fkey"
    alter table(:alerts) do
      modify(:code, :string, null: false)
      modify(:title, :string, null: false)
      modify(:description, :string, null: false)

      modify(:priority, :integer, null: false)

      modify(:receiver_id, references(:users, type: :id, on_delete: :nothing))
      modify(:sender_id, references(:users, type: :id, on_delete: :nothing))
    end
  end
end
