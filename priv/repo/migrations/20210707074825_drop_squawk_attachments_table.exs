defmodule Flight.Repo.Migrations.DropSquawkAttachmentsTable do
  use Ecto.Migration

  def change do
    drop_if_exists table("squawk_attachments")
  end
end
