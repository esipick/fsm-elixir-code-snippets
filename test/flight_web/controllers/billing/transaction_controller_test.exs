defmodule FlightWeb.Billing.TransactionControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "GET /billing/transactions" do
    test "renders for all except renters", %{conn: conn} do
      for role_slug <- ["admin", "dispatcher", "instructor", "student"] do
        user = user_fixture() |> assign_role(role_slug)

        content =
          conn
          |> web_auth(user)
          |> get("/billing/transactions")
          |> html_response(200)

        assert content =~ user.first_name

        if role_slug == "student" do
          refute content =~ "New Invoice"
        else
          assert content =~ "New Invoice"
        end
      end
    end

    test "renders only own student transactions", %{conn: conn} do
      user = student_fixture(%{first_name: "Correct", last_name: "User"})
      another_user = student_fixture(%{first_name: "Another", last_name: "Student"})

      _transaction = transaction_fixture(%{}, user)
      _another_transaction = transaction_fixture(%{}, another_user)

      content =
        conn
        |> web_auth(user)
        |> get("/billing/transactions")
        |> html_response(200)

      refute content =~ "New Invoice"
      assert content =~ "Correct User"
      refute content =~ "Another Student"
    end

    test "redirects renters", %{conn: conn} do
      user = user_fixture() |> assign_role("renter")

      conn =
        conn
        |> web_auth(user)
        |> get("/billing/transactions")

      assert redirected_to(conn) == "/login"
    end
  end
end
