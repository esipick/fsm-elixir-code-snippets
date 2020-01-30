defmodule FlightWeb.Billing.TransactionControllerTest do
  use FlightWeb.ConnCase, async: false

  describe "GET /billing/transactions" do
    test "render transactions for all schools as superadmin", %{conn: conn} do
      another_school = school_fixture(%{name: "another school"})
      student = student_fixture(%{}, another_school)
      transaction_fixture(%{}, student, instructor_fixture(), another_school)

      content =
        conn
        |> web_auth_superadmin()
        |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
        |> get("/billing/transactions")
        |> html_response(200)

      assert content =~ "<th>School</th>"
      assert content =~ another_school.name
    end

    test "render message when no transaction", %{conn: conn} do
      content =
        conn
        |> web_auth_superadmin()
        |> get("/billing/transactions")
        |> html_response(200)

      refute content =~ "<th>Student name</th>"
      assert content =~ "No results found"
    end

    @tag :integration
    test "renders for all except renters", %{conn: conn} do
      for role_slug <- ["admin", "dispatcher", "instructor", "student"] do
        user = user_fixture() |> assign_role(role_slug)
        transaction_fixture(%{}, user)

        content =
          conn
          |> web_auth(user)
          |> get("/billing/transactions")
          |> html_response(200)

        refute content =~ "<th>School</th>"

        button_shown = content =~ "New Invoice"

        case role_slug do
          "student" -> refute button_shown
          _ -> assert button_shown
        end
      end
    end

    @tag :integration
    test "renders transactions filtered by student name", %{conn: conn} do
      instructor = instructor_fixture()
      user = student_fixture(%{first_name: "Correct", last_name: "User"})
      another_user = student_fixture(%{first_name: "Another", last_name: "Student"})

      _transaction = transaction_fixture(%{}, user)
      _another_transaction = transaction_fixture(%{}, another_user)

      content =
        conn
        |> web_auth(instructor)
        |> get("/billing/transactions?search=corr")
        |> html_response(200)

      assert content =~ user.first_name
      refute content =~ another_user.first_name
    end

    @tag :integration
    test "renders transactions filtered by date", %{conn: conn} do
      instructor = instructor_fixture()
      user = student_fixture(%{first_name: "Correct", last_name: "User"})
      another_user = student_fixture(%{first_name: "Another", last_name: "Student"})

      _transaction = transaction_fixture(%{}, user)
      _another_transaction = transaction_fixture(%{}, another_user)

      now = Timex.now() |> Timex.to_date()
      {:ok, start_date} = now |> Timex.shift(days: -2) |> Timex.format("{0M}-{0D}-{YYYY}")
      {:ok, end_date} = now |> Timex.shift(days: -1) |> Timex.format("{0M}-{0D}-{YYYY}")

      content =
        conn
        |> web_auth(instructor)
        |> get("/billing/transactions?start_date=#{start_date}&end_date=#{end_date}")
        |> html_response(200)

      refute content =~ user.first_name
      refute content =~ another_user.first_name

      {:ok, end_date} = now |> Timex.format("{0M}-{0D}-{YYYY}")

      content =
        conn
        |> web_auth(instructor)
        |> get("/billing/transactions?start_date=#{start_date}&end_date=#{end_date}")
        |> html_response(200)

      assert content =~ user.first_name
    end

    @tag :integration
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

    @tag :integration
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
