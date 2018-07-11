defmodule FlightWeb.Admin.TransactionControllerTest do
  use FlightWeb.ConnCase, async: false

  describe "POST /admin/transaction/:id/cancel" do
    test "cancels transaction", %{conn: conn} do
      transaction = transaction_fixture(%{state: "pending"})

      admin = admin_fixture()

      conn =
        conn
        |> web_auth(admin)
        |> post("/admin/transactions/#{transaction.id}/cancel")

      assert refresh(transaction).state == "canceled"

      assert redirected_to(conn) == "/admin/users/#{transaction.user.id}?tab=billing"
    end
  end
end
