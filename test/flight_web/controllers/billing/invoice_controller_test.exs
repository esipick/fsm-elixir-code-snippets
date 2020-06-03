defmodule FlightWeb.Billing.InvoiceControllerTest do
  use FlightWeb.ConnCase, async: false

  alias Flight.Repo
  alias Flight.Billing.Invoice

  describe "GET /billing/invoices" do
    test "render invoices for all schools as superadmin", %{conn: conn} do
      another_school = school_fixture(%{name: "another school"})
      student = student_fixture(%{}, another_school)
      invoice_fixture(%{}, student)

      content =
        conn
        |> web_auth_superadmin()
        |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
        |> get("/billing/invoices")
        |> html_response(200)

      assert content =~ "<th>School</th>"
      assert content =~ another_school.name
    end

    @tag :integration
    test "render message when no invoices", %{conn: conn} do
      content =
        conn
        |> web_auth_superadmin()
        |> get("/billing/invoices")
        |> html_response(200)

      refute content =~ "<th>Student name</th>"
      assert content =~ "No results found"
    end

    @tag :integration
    test "renders for all except renters", %{conn: conn} do
      for role_slug <- ["admin", "dispatcher", "instructor", "student"] do
        user = user_fixture() |> assign_role(role_slug)

        content =
          conn
          |> web_auth(user)
          |> get("/billing/invoices")
          |> html_response(200)

        assert content =~ user.first_name
        refute content =~ "<th>School</th>"

        assert content =~ "New Invoice"
      end
    end

    @tag :integration
    test "should render correct appointment time", %{conn: conn} do
      student = student_fixture()

      appointment =
        past_appointment_fixture(
          %{start_at: ~N[2018-03-03 10:00:00], end_at: ~N[2018-03-03 11:00:00]},
          student
        )

      invoice = invoice_fixture(%{appointment_id: appointment.id}, student)

      content =
        conn
        |> web_auth(student)
        |> get("/billing/invoices/#{invoice.id}")
        |> html_response(200)

      assert content =~ "Mar 3, 2018"
      assert content =~ "10:00AM - 11:00AM"
    end

    @tag :integration
    test "renders invoices filtered by student name", %{conn: conn} do
      instructor = instructor_fixture()
      student = student_fixture(%{first_name: "Correct", last_name: "User"})
      student_2 = student_fixture(%{first_name: "Another", last_name: "Student"})
      student_3 = student_fixture(%{first_name: "Archived", last_name: "User"})

      _invoice = invoice_fixture(%{}, student)
      _another_invoice = invoice_fixture(%{}, student_2)
      _archived_invoice = invoice_fixture(%{archived: true}, student_3)

      content =
        conn
        |> web_auth(instructor)
        |> get("/billing/invoices?search=corr")
        |> html_response(200)

      assert content =~ student.first_name
      refute content =~ student_2.first_name
      refute content =~ "Archived User"
    end

    @tag :integration
    test "renders invoices filtered by aircraft tail no", %{conn: conn} do
      instructor = instructor_fixture()
      student = student_fixture(%{first_name: "Correct", last_name: "User"})
      another_student = student_fixture(%{first_name: "Another", last_name: "Student"})

      aircraft = aircraft_fixture(%{tail_number: "N4685"})

      _invoice =
        invoice_fixture(
          %{
            line_items: [
              %{
                description: "flight hours",
                rate: 1500,
                quantity: 10,
                amount: 15000,
                type: :aircraft,
                aircraft_id: aircraft.id
              }
            ]
          },
          student
        )

      _another_invoice = invoice_fixture(%{}, another_student)

      content =
        conn
        |> web_auth(instructor)
        |> get("/billing/invoices?search=N46")
        |> html_response(200)

      assert content =~ student.first_name
      refute content =~ another_student.first_name
    end

    @tag :integration
    test "renders invoices filtered by date", %{conn: conn} do
      instructor = instructor_fixture()
      student = student_fixture(%{first_name: "Correct", last_name: "User"})
      another_student = student_fixture(%{first_name: "Another", last_name: "Student"})

      _invoice = invoice_fixture(%{}, student)
      _another_invoice = invoice_fixture(%{}, another_student)

      now = Timex.now() |> Timex.to_date()
      {:ok, start_date} = now |> Timex.shift(days: -2) |> Timex.format("{0M}-{0D}-{YYYY}")
      {:ok, end_date} = now |> Timex.shift(days: -1) |> Timex.format("{0M}-{0D}-{YYYY}")

      content =
        conn
        |> web_auth(instructor)
        |> get("/billing/invoices?start_date=#{start_date}&end_date=#{end_date}")
        |> html_response(200)

      refute content =~ student.first_name
      refute content =~ another_student.first_name

      {:ok, end_date} = now |> Timex.format("{0M}-{0D}-{YYYY}")

      content =
        conn
        |> web_auth(instructor)
        |> get("/billing/invoices?start_date=#{start_date}&end_date=#{end_date}")
        |> html_response(200)

      assert content =~ student.first_name
    end

    @tag :integration
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

      assert content =~ "New Invoice"
      assert content =~ "Correct User"
      refute content =~ "Another Student"
    end

    @tag :integration
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
    @tag :integration
    test "renders invoice for student", %{conn: conn} do
      user = student_fixture()

      invoice = invoice_fixture(%{}, user)

      content =
        conn
        |> web_auth(user)
        |> get("/billing/invoices/#{invoice.id}")
        |> html_response(200)

      assert content =~ "Edit"
      assert content =~ "Invoice ##{invoice.id} (pending)"
    end

    @tag :integration
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
    @tag :integration
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

    @tag :integration
    test "redirects students", %{conn: conn} do
      user = student_fixture()

      invoice = invoice_fixture(%{}, student_fixture())

      conn =
        conn
        |> web_auth(user)
        |> get("/billing/invoices/#{invoice.id}/edit")

      assert redirected_to(conn) == "/student/profile"
    end

    @tag :integration
    test "redirects student when own invoice is paid", %{conn: conn} do
      user = student_fixture()

      invoice = invoice_fixture(%{status: :paid}, user)

      conn =
        conn
        |> web_auth(user)
        |> get("/billing/invoices/#{invoice.id}/edit")

      assert redirected_to(conn) == "/billing/invoices/#{invoice.id}"
    end
  end

  describe "DELETE /billing/invoices/:id" do
    @tag :integration
    test "admin, instructor and dispatcher able to delete any pending invoices", %{conn: conn} do
      for role_slug <- ["admin", "dispatcher", "instructor"] do
        user = user_fixture() |> assign_role(role_slug)
        invoice = invoice_fixture()

        content =
          conn
          |> web_auth(user)
          |> get("/billing/invoices")
          |> html_response(200)

        assert content =~ "btn btn-danger btn-sm ml-1 _delete_button"

        content =
          conn
          |> web_auth(user)
          |> get("/billing/invoices/#{invoice.id}")
          |> html_response(200)

        assert content =~ "btn btn-danger _delete_button"

        content =
          conn
          |> web_auth(user)
          |> delete("/billing/invoices/#{invoice.id}")

        invoice = Repo.get(Invoice, invoice.id)

        assert invoice.archived
        assert redirected_to(content) == "/billing/invoices"
      end
    end

    @tag :integration
    test "admin, instructor and dispatcher cannot delete paid invoices", %{conn: conn} do
      for role_slug <- ["admin", "dispatcher", "instructor"] do
        user = user_fixture() |> assign_role(role_slug)
        invoice = invoice_fixture(%{status: :paid})

        content =
          conn
          |> web_auth(user)
          |> delete("/billing/invoices/#{invoice.id}")

        invoice = Repo.get(Invoice, invoice.id)

        refute invoice.archived
      end
    end

    @tag :integration
    test "student shouldn't to be able to delete invoices", %{conn: conn} do
      student = student_fixture()
      invoice = invoice_fixture(%{}, student)

      content =
        conn
        |> web_auth(student)
        |> get("/billing/invoices")
        |> html_response(200)

      refute content =~ "btn btn-danger btn-sm _delete_button"

      content =
        conn
        |> web_auth(student)
        |> get("/billing/invoices/#{invoice.id}")
        |> html_response(200)

      refute content =~ "btn btn-danger _delete_button"

      content =
        conn
        |> web_auth(student)
        |> delete("/billing/invoices/#{invoice.id}")

      invoice = Repo.get(Invoice, invoice.id)

      refute invoice.archived
      assert redirected_to(content) == "/student/profile"
    end
  end
end
