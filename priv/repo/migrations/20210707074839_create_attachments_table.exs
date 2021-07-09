defmodule Flight.Repo.Migrations.CreateAttachmentsTable do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  def change do
    DocumentType.create_type
    AttachmentType.create_type
    create table(:attachments) do
      add :url, :string
      add :file_name, :string
      add :file_extension, :string
      add :size_in_bytes, :integer
      add(:expiration_date, :naive_datetime)

      add(:user_id, references(:users, on_delete: :nothing), null: true)
      add(:squawk_id, references(:squawks, on_delete: :nothing), null: true)
      add :inspection_id, references(:inspections, on_delete: :delete_all)
      add(:document_type, DocumentType.type())
      add(:attachment_type, AttachmentType.type())

      soft_delete_columns()
      timestamps()
    end
  end

end