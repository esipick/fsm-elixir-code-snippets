defmodule FlightWeb.Billing.TransactionController do
  use FlightWeb, :controller

  alias FlightWeb.{Pagination, Billing.TransactionStruct}
  alias Flight.Auth.InvoicePolicy

  def index(conn, params) do
    page_params = Pagination.params(params)
    user = conn.assigns.current_user

    options = if InvoicePolicy.create?(user) do
      %{}
    else
      %{"user_id" => user.id}
    end

    page = Flight.Queries.Transaction.page(conn, page_params, options)

    transactions =
      page
      |> Enum.map(fn transaction -> TransactionStruct.build(transaction) end)

    render(conn, "index.html", page: page, transactions: transactions)
  end
end
