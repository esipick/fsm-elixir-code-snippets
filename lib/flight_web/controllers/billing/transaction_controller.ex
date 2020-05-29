defmodule FlightWeb.Billing.TransactionController do
  use FlightWeb, :controller

  alias FlightWeb.{Pagination, Billing.TransactionStruct}

  import Flight.Auth.Authorization

  def index(conn, params) do
    page_params = Pagination.params(params)
    user = conn.assigns.current_user

    page =
      if staff_member?(user) do
        Flight.Queries.Transaction.page(conn, page_params, params)
      else
        options = %{user_id: user.id}
        Flight.Queries.Transaction.own_transactions(conn, page_params, options)
      end

    transactions =
      page
      |> Enum.map(fn transaction -> TransactionStruct.build(transaction) end)

    render(conn, "index.html", page: page, transactions: transactions, params: params)
  end
end
