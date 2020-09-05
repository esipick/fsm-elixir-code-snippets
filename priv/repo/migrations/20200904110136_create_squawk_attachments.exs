defmodule Flight.Repo.Migrations.CreateSquawkAttachments do
  use Ecto.Migration

  def change do
    create table(:squawk_attachments) do
      add(:squawk_id, references(:squawks, type: :binary_id, on_delete: :delete_all))
      add(:attachment, :string, null: false)

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end
