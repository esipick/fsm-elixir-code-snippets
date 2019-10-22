defmodule FlightWeb.Admin.Billing.TransactionController do
  use FlightWeb, :controller

  import Ecto.Query

  alias Flight.{Repo, Billing.Transaction}
  alias FlightWeb.{Pagination, Admin.Billing.TransactionStruct}

  def index(conn, params) do
    page_params = Pagination.params(params)

    page =
      from(t in Transaction)
      |> Repo.paginate(page_params)

    transactions =
      page
      |> Enum.map(fn transaction -> TransactionStruct.build(transaction) end)

    render(conn, "index.html", page: page, transactions: transactions)
  end
end
