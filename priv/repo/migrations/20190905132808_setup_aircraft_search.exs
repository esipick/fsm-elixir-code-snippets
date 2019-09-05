defmodule Flight.Repo.Migrations.SetupAircraftSearch do
  @moduledoc """
  Create index for aircrafts search
  """

  use Ecto.Migration

  def up do
    execute("""
    CREATE INDEX aircrafts_trgm_idx ON aircrafts USING GIN (to_tsvector('english', tail_number))
    """)
  end

  def down do
    execute("DROP INDEX aircrafts_trgm_idx")
  end
end
