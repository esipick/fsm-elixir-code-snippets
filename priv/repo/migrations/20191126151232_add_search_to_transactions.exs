defmodule Flight.Repo.Migrations.AddSearchToTransactions do
  @moduledoc """
  Create index for transactions search
  """

  use Ecto.Migration

  def up do
    execute("""
    CREATE INDEX transactions_trgm_idx ON transactions USING GIN (to_tsvector('english', first_name || ' ' || last_name))
    """)
  end

  def down do
    execute("DROP INDEX transactions_trgm_idx")
  end
end
