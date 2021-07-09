defmodule Flight.Repo.Migrations.DropSquawksAndSquawksAttachmentsTable do
  use Ecto.Migration

  def change do
    drop_if_exists table("squawk_attachments")
    drop_if_exists table("attachments")
    drop_if_exists table("squawks")
  end
end
