defmodule Fsm.Billing.InvoicesQueries do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  alias Fsm.SchoolScope
  alias Fsm.Billing.InvoiceCustomLineItem

  def list_custom_line_items_query(school_context) do
    InvoiceCustomLineItem
    |> SchoolScope.scope_query(school_context)
    |> order_by([c], desc: c.id)
  end
end
