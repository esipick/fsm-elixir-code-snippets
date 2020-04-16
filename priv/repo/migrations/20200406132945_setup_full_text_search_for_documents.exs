defmodule Flight.Repo.Migrations.SetupFullTextSearchForDocuments do
  use Ecto.Migration

  def up do
    execute("""
    CREATE INDEX documents_trgm_idx ON documents USING GIN (to_tsvector('english',
      file || ' '))
    """)
  end

  def down do
    execute("DROP INDEX documents_trgm_idx")
  end
end
