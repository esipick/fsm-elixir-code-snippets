defmodule Flight.Repo.Migrations.SetupFullTextSearch do
  @moduledoc """
  Create postgres extension and indices
  """

  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION pg_trgm")

    execute("""
    CREATE INDEX users_trgm_idx ON users USING GIN (to_tsvector('english',
      email || ' ' || first_name || ' ' || last_name || ' ' || replace(phone_number, '-', '') || ' ' ||
      coalesce(address_1, ' ') || ' ' ||
      coalesce(city, ' ') || ' ' ||
      coalesce(zipcode, ' ') || ' ' ||
      coalesce(state, ' ')))
    """)
  end

  def down do
    execute("DROP INDEX users_trgm_idx")
    execute("DROP EXTENSION pg_trgm")
  end
end
