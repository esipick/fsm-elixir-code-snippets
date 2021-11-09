defmodule Fsm.Billing.Invoices do
  import Ecto.Query, warn: false
  alias Flight.Billing.{
    Invoice
    }
  alias Flight.Repo
  alias Fsm.Billing.InvoicesQueries

  def list_custom_line_items(conn) do
    InvoicesQueries.list_custom_line_items_query(conn)
    |> Repo.all
  end
  def getCurrentMonthCourseAdminInvoice(school_id) do
    from(
      i in Invoice,
      where: i.school_id == ^school_id,
      order_by: [desc: i.inserted_at],
      limit: 1
    )
    |> Flight.Repo.one()
  end
end
