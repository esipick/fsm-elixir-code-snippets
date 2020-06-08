defmodule Flight.Repo.Migrations.AddTitleToDocuments do
  use Ecto.Migration

  def up do
    alter table(:documents) do
      add(:title, :string)
    end

    execute("DROP INDEX documents_trgm_idx")

    execute("""
    CREATE INDEX documents_trgm_idx ON documents USING GIN (to_tsvector('english',
      coalesce(title, ' ') || ' ' || file))
    """)
  end

  def down do
    alter table(:documents) do
      remove(:title, :string)
    end

    execute("DROP INDEX documents_trgm_idx")

    execute("""
    CREATE INDEX documents_trgm_idx ON documents USING GIN (to_tsvector('english',
      file))
    """)
  end
end
