defmodule FlightWeb.Billing.TransactionController do
  use FlightWeb, :controller

  alias FlightWeb.{Pagination, Billing.TransactionStruct}
  alias Flight.Repo
  alias Flight.Billing.Transaction

  import Flight.Auth.Authorization

  plug(:get_transaction when action in [:show])

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

  def show(conn, _) do
    transaction = TransactionStruct.build(conn.assigns.transaction, %{render_invoices: true})

    render(conn, "show.html",
      transaction: transaction,
      user: conn.assigns.current_user,
      skip_shool_select: true
    )
  end

  defp get_transaction(conn, _) do
    transaction = Repo.get(Transaction, conn.params["id"])

    if transaction do
      assign(conn, :transaction, transaction)
    else
      conn
      |> send_resp(404, "")
      |> halt()
    end
  end
end
