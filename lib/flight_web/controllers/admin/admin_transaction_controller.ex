defmodule FlightWeb.Admin.TransactionController do
  use FlightWeb, :controller

  alias Flight.Billing

  def cancel(conn, %{"transaction_id" => transaction_id}) do
    transaction = Billing.get_transaction(transaction_id, conn)

    case Billing.cancel_transaction(transaction) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully canceled transaction.")
        |> redirect(to: "/admin/users/#{transaction.user_id}?tab=billing")

      _ ->
        conn
        |> put_flash(:error, "Failed to cancel transaction.")
        |> redirect(to: "/admin/users/#{transaction.user_id}?tab=billing")
    end
  end
end
