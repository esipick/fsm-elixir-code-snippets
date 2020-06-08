defmodule Flight.Repo.Migrations.AddNameToAircrafts do
  use Ecto.Migration

  def change do
    alter table(:aircrafts) do
      add(:name, :string)
    end

    execute("DROP INDEX aircrafts_trgm_idx")

    execute("""
    CREATE INDEX aircrafts_trgm_idx ON aircrafts USING GIN (to_tsvector('english',
      coalesce(tail_number, ' ') || ' ' ||
      coalesce(name, ' ') || ' '
    ))
    """)
  end

  def down do
    execute("DROP INDEX aircrafts_trgm_idx")

    execute("""
    CREATE INDEX aircrafts_trgm_idx ON aircrafts USING GIN (to_tsvector('english', tail_number))
    """)
  end
end
