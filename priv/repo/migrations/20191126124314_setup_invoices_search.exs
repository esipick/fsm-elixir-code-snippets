defmodule Flight.Repo.Migrations.SetupInvoicesSearch do
  @moduledoc """
  Create index for invoices search
  """

  use Ecto.Migration

  def up do
    execute("""
    CREATE INDEX invoices_trgm_idx ON invoices USING GIN (to_tsvector('english', payer_name))
    """)
  end

  def down do
    execute("DROP INDEX invoices_trgm_idx")
  end
end
