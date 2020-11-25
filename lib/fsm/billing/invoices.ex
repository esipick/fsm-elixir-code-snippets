defmodule Fsm.Billing.Invoices do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Fsm.Billing.InvoicesQueries

  def list_custom_line_items(conn) do
    InvoicesQueries.list_custom_line_items_query(conn)
    |> Repo.all
  end
end
