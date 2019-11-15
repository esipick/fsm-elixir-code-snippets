defmodule FlightWeb.Billing.InvoiceControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "GET /billing/invoices" do
    test "renders for all except renters", %{conn: conn} do
      for role_slug <- ["admin", "dispatcher", "instructor", "student"] do
        user = user_fixture() |> assign_role(role_slug)

        content =
          conn
          |> web_auth(user)
          |> get("/billing/invoices")
          |> html_response(200)

        assert content =~ user.first_name

        if role_slug == "student" do
          refute content =~ "New Invoice"
        else
          assert content =~ "New Invoice"
        end
      end
    end

    test "renders only own student invoices", %{conn: conn} do
      user = student_fixture(%{first_name: "Correct", last_name: "User"})
      another_user = student_fixture(%{first_name: "Another", last_name: "Student"})

      _invoice = invoice_fixture(%{}, user)
      _another_invoice = invoice_fixture(%{}, another_user)

      content =
        conn
        |> web_auth(user)
        |> get("/billing/invoices")
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
        |> get("/billing/invoices")

      assert redirected_to(conn) == "/login"
    end
  end

  describe "GET /billing/invoices/:id" do
    test "renders invoice for student", %{conn: conn} do
      user = student_fixture()

      invoice = invoice_fixture(%{}, user)

      content =
        conn
        |> web_auth(user)
        |> get("/billing/invoices/#{invoice.id}")
        |> html_response(200)

      refute content =~ "Edit"
      assert content =~ "Invoice ##{invoice.id} (pending)"
    end

    test "redirects other students", %{conn: conn} do
      user = student_fixture()
      another_user = student_fixture()

      invoice = invoice_fixture(%{}, another_user)

      conn =
        conn
        |> web_auth(user)
        |> get("/billing/invoices/#{invoice.id}")

      assert redirected_to(conn) == "/student/profile"
    end
  end

  describe "GET /billing/invoices/:id/edit" do
    test "renders for all except students and renters", %{conn: conn} do
      for role_slug <- ["admin", "dispatcher", "instructor"] do
        user = user_fixture() |> assign_role(role_slug)

        invoice = invoice_fixture(%{}, student_fixture())

        content =
          conn
          |> web_auth(user)
          |> get("/billing/invoices/#{invoice.id}/edit")
          |> html_response(200)

        assert content =~ "Components.InvoiceForm"
      end
    end

    test "redirects students", %{conn: conn} do
      user = student_fixture()

      invoice = invoice_fixture(%{}, student_fixture())

      conn =
        conn
        |> web_auth(user)
        |> get("/billing/invoices/#{invoice.id}/edit")

      assert redirected_to(conn) == "/student/profile"
    end
  end
end
