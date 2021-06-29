defmodule Flight.Repo.Migrations.AlterSquawksAttachmentsTable do
  use Ecto.Migration

  def change do
    alter table("squawk_attachments") do
      add(:url, :string)
      add(:file_name, :string)
      add(:file_extension, :string)
      add(:size_in_bytes, :integer)
      add(:expiration_date, :naive_datetime)
      add(:document_type, DocumentType)
      add(:attchment_type, AttachmentType)
    end
  end
end