defmodule FlightWeb.API.InvoiceControllerTest do
  use FlightWeb.ConnCase

  alias Flight.Repo
  alias FlightWeb.API.InvoiceView
  alias Flight.Billing.Invoice

  describe "POST /api/invoices" do
    @tag :integration
    test "renders unauthorized", %{conn: conn} do
      student = student_fixture()
      invoice_params = %{}

      conn
      |> auth(student)
      |> post("/api/invoices", %{invoice: invoice_params})
      |> json_response(401)
    end

    @tag :integration
    test "renders invoice json errors", %{conn: conn} do
      instructor = instructor_fixture()
      invoice_params = %{}

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{invoice: invoice_params})
        |> json_response(422)

      errors = %{
        "date" => ["can't be blank"],
        "payment_option" => ["can't be blank"],
        "total" => ["can't be blank"],
        "total_amount_due" => ["can't be blank"],
        "total_tax" => ["can't be blank"],
        "user_id" => ["One of these fields must be present: [:user_id, :payer_name]"]
      }

      assert json["errors"] == errors
    end

    @tag :integration
    test "creates invoice", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(student)

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{invoice: invoice_params})
        |> json_response(201)

      invoice = Repo.get_by(Invoice, user_id: student.id) |> preload_invoice

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates invoice for anonymous payer", %{conn: conn} do
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(%Flight.Accounts.User{}, %{ payer_name: "Foo Bar" })

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{invoice: invoice_params})
        |> json_response(201)

      invoice = Repo.get_by(Invoice, payer_name: "Foo Bar") |> preload_invoice

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "renders stripe error", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(student, %{payment_option: "cc"})

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{pay_off: true, invoice: invoice_params})
        |> json_response(400)

      invoice = Repo.get_by(Invoice, user_id: student.id) |> preload_invoice

      transaction = List.first(invoice.transactions)

      assert is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "failed"
      assert transaction.total == 24000
      assert transaction.type == "credit"
      assert transaction.payment_option == :cc
      assert transaction.paid_by_charge == nil

      assert String.starts_with?(json["stripe_error"], "No such customer: cus_")
    end

    @tag :integration
    test "creates invoice when payment option is not balance or cc", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(student, %{payment_option: "cash"})

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{pay_off: true, invoice: invoice_params})
        |> json_response(201)

      invoice = Repo.get_by(Invoice, user_id: student.id) |> preload_invoice

      transaction = List.first(invoice.transactions)

      assert is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "completed"
      assert transaction.total == 24000
      assert transaction.type == "debit"
      assert transaction.payment_option == :cash
      assert transaction.paid_by_cash == 24000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates and pays invoice for anonymous payer", %{conn: conn} do
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(
        %Flight.Accounts.User{},
        %{payer_name: "Foo Bar", payment_option: "cash"}
      )

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{pay_off: true, invoice: invoice_params})
        |> json_response(201)

      invoice = Repo.get_by(Invoice, payer_name: "Foo Bar") |> preload_invoice

      transaction = List.first(invoice.transactions)

      assert is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)
      assert transaction.first_name == "Foo Bar"

      assert transaction.state == "completed"
      assert transaction.total == 24000
      assert transaction.type == "debit"
      assert transaction.payment_option == :cash
      assert transaction.paid_by_cash == 24000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates invoice when payment option is balance (enough)", %{conn: conn} do
      student = student_fixture(%{balance: 30000})
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(student)

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{pay_off: true, invoice: invoice_params})
        |> json_response(201)

      invoice = Repo.get_by(Invoice, user_id: student.id) |> preload_invoice

      transaction = List.first(invoice.transactions)

      assert invoice.user.balance == 6000

      assert is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "completed"
      assert transaction.total == 24000
      assert transaction.type == "debit"
      assert transaction.payment_option == :balance
      assert transaction.paid_by_balance == 24000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates invoice when payment option is balance (not enough)", %{conn: conn} do
      {student, _} = student_fixture(%{balance: 20000}) |> real_stripe_customer()
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(student)

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{pay_off: true, invoice: invoice_params})
        |> json_response(201)

      invoice = Repo.get_by(Invoice, user_id: student.id) |> preload_invoice

      balance_transaction = List.last(invoice.transactions)
      stripe_transaction = List.first(invoice.transactions)

      assert is_nil(balance_transaction.stripe_charge_id)
      assert not is_nil(balance_transaction.completed_at)

      assert balance_transaction.state == "completed"
      assert balance_transaction.total == 20000
      assert balance_transaction.type == "debit"
      assert balance_transaction.payment_option == :balance
      assert balance_transaction.paid_by_balance == 20000

      assert not is_nil(stripe_transaction.completed_at)
      assert not is_nil(stripe_transaction.stripe_charge_id)

      assert stripe_transaction.state == "completed"
      assert stripe_transaction.total == 4000
      assert stripe_transaction.type == "credit"
      assert stripe_transaction.payment_option == :cc
      assert stripe_transaction.paid_by_charge == 4000

      assert invoice.user.balance == 0
      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates only charge transaction when user balance is empty", %{conn: conn} do
      {student, _} = student_fixture() |> real_stripe_customer()
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(student)

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{pay_off: true, invoice: invoice_params})
        |> json_response(201)

      invoice = Repo.get_by(Invoice, user_id: student.id) |> preload_invoice

      transaction = List.first(invoice.transactions)

      assert length(invoice.transactions) == 1

      assert not is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "completed"
      assert transaction.total == 24000
      assert transaction.type == "credit"
      assert transaction.payment_option == :cc
      assert transaction.paid_by_charge == 24000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates invoice when payment option is cc", %{conn: conn} do
      {student, _} = student_fixture() |> real_stripe_customer()
      instructor = instructor_fixture()
      invoice_params = invoice_attrs(student, %{payment_option: "cc"})

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{pay_off: true, invoice: invoice_params})
        |> json_response(201)

      invoice = Repo.get_by(Invoice, user_id: student.id) |> preload_invoice

      transaction = List.first(invoice.transactions)

      assert not is_nil(transaction.completed_at)
      assert not is_nil(transaction.stripe_charge_id)

      assert transaction.state == "completed"
      assert transaction.total == 24000
      assert transaction.type == "credit"
      assert transaction.payment_option == :cc
      assert transaction.paid_by_charge == 24000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end
  end

  describe "GET /api/invoices" do
    @tag :integration
    test "renders unauthorized", %{conn: conn} do
      student = student_fixture()

      conn
      |> auth(student)
      |> get("/api/invoices")
      |> json_response(401)
    end

    @tag :integration
    test "renders invoices", %{conn: conn} do
      invoice1 = invoice_fixture()
      invoice2 = invoice_fixture()
      instructor = instructor_fixture()

      response =
        conn
        |> auth(instructor)
        |> get("/api/invoices/")

      json = json_response(response, 200)
      headers = response.resp_headers

      assert json == render_json(InvoiceView, "index.json", invoices: [
        preload_invoice(invoice1),
        preload_invoice(invoice2)
      ])

      assert Enum.member?(headers, {"total", "2"})
      assert Enum.member?(headers, {"per-page", "50"})
      assert Enum.member?(headers, {"total-pages", "1"})
      assert Enum.member?(headers, {"page-number", "1"})
    end
  end

  describe "GET /api/invoices/:id" do
    @tag :integration
    test "renders unauthorized", %{conn: conn} do
      invoice = invoice_fixture()
      student = student_fixture()

      conn
      |> auth(student)
      |> get("/api/invoices/#{invoice.id}")
      |> json_response(401)
    end

    @tag :integration
    test "renders invoice", %{conn: conn} do
      invoice = invoice_fixture()
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> get("/api/invoices/#{invoice.id}")
        |> json_response(200)

      invoice =
        Repo.get(Invoice, invoice.id)
        |> preload_invoice

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end
  end

  describe "PUT /api/invoices/:id" do
    @tag :integration
    test "renders unauthorized for student", %{conn: conn} do
      invoice = invoice_fixture()
      student = student_fixture()
      invoice_params = %{}

      conn
      |> auth(student)
      |> put("/api/invoices/#{invoice.id}", %{invoice: invoice_params})
      |> json_response(401)
    end

    @tag :integration
    test "renders unauthorized when invoice has already paid", %{conn: conn} do
      invoice = invoice_fixture(%{status: "paid"})
      student = student_fixture()
      invoice_params = %{}

      conn
      |> auth(student)
      |> put("/api/invoices/#{invoice.id}", %{invoice: invoice_params})
      |> json_response(401)
    end

    @tag :integration
    test "renders invoice json errors", %{conn: conn} do
      invoice = invoice_fixture()
      instructor = instructor_fixture()
      invoice_params = %{total_amount_due: nil}

      json =
        conn
        |> auth(instructor)
        |> put("/api/invoices/#{invoice.id}", %{invoice: invoice_params})
        |> json_response(422)

      errors = %{"total_amount_due" => ["can't be blank"]}

      assert json["errors"] == errors
    end

    @tag :integration
    test "updates invoice", %{conn: conn} do
      invoice = invoice_fixture()
      instructor = instructor_fixture()
      invoice_params = %{total_amount_due: 25000}

      json =
        conn
        |> auth(instructor)
        |> put("/api/invoices/#{invoice.id}", %{invoice: invoice_params})
        |> json_response(200)

      invoice = preload_invoice(invoice)

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "renders stripe error", %{conn: conn} do
      invoice = invoice_fixture(%{payment_option: "cc"})
      instructor = instructor_fixture()
      invoice_params = %{total_amount_due: 25000}

      json =
        conn
        |> auth(instructor)
        |> put("/api/invoices/#{invoice.id}", %{pay_off: true, invoice: invoice_params})
        |> json_response(400)

      invoice = preload_invoice(invoice)

      transaction = List.first(invoice.transactions)

      assert is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "failed"
      assert transaction.total == 25000
      assert transaction.type == "credit"
      assert transaction.payment_option == :cc
      assert transaction.paid_by_charge == nil

      assert String.starts_with?(json["stripe_error"], "No such customer: cus_")
    end

    @tag :integration
    test "creates invoice when payment option is not balance or cc", %{conn: conn} do
      invoice = invoice_fixture(%{payment_option: "cash"})
      instructor = instructor_fixture()
      invoice_params = %{total_amount_due: 25000}

      json =
        conn
        |> auth(instructor)
        |> put("/api/invoices/#{invoice.id}", %{pay_off: true, invoice: invoice_params})
        |> json_response(200)

      invoice = preload_invoice(invoice)

      transaction = List.first(invoice.transactions)

      assert is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "completed"
      assert transaction.total == 25000
      assert transaction.type == "debit"
      assert transaction.payment_option == :cash
      assert transaction.paid_by_cash == 25000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates invoice when payment option is balance (enough)", %{conn: conn} do
      student = student_fixture(%{balance: 30000})
      invoice = invoice_fixture(%{}, student)
      instructor = instructor_fixture()
      invoice_params = %{total_amount_due: 25000}

      json =
        conn
        |> auth(instructor)
        |> put("/api/invoices/#{invoice.id}", %{pay_off: true, invoice: invoice_params})
        |> json_response(200)

      invoice = preload_invoice(invoice)

      transaction = List.first(invoice.transactions)

      assert invoice.user.balance == 5000

      assert is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "completed"
      assert transaction.total == 25000
      assert transaction.type == "debit"
      assert transaction.payment_option == :balance
      assert transaction.paid_by_balance == 25000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates invoice when payment option is balance (not enough)", %{conn: conn} do
      {student, _} = student_fixture(%{balance: 20000}) |> real_stripe_customer()
      invoice = invoice_fixture(%{}, student)
      instructor = instructor_fixture()
      invoice_params = %{total_amount_due: 25000}

      json =
        conn
        |> auth(instructor)
        |> put("/api/invoices/#{invoice.id}", %{pay_off: true, invoice: invoice_params})
        |> json_response(200)
      invoice = preload_invoice(invoice)

      balance_transaction = List.last(invoice.transactions)
      stripe_transaction = List.first(invoice.transactions)

      assert is_nil(balance_transaction.stripe_charge_id)
      assert not is_nil(balance_transaction.completed_at)

      assert balance_transaction.state == "completed"
      assert balance_transaction.total == 20000
      assert balance_transaction.type == "debit"
      assert balance_transaction.payment_option == :balance
      assert balance_transaction.paid_by_balance == 20000

      assert not is_nil(stripe_transaction.completed_at)
      assert not is_nil(stripe_transaction.stripe_charge_id)

      assert stripe_transaction.state == "completed"
      assert stripe_transaction.total == 5000
      assert stripe_transaction.type == "credit"
      assert stripe_transaction.payment_option == :cc
      assert stripe_transaction.paid_by_charge == 5000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates only charge transaction when user balance is empty", %{conn: conn} do
      {student, _} = student_fixture() |> real_stripe_customer()
      invoice = invoice_fixture(%{}, student)
      instructor = instructor_fixture()
      invoice_params = %{total_amount_due: 25000}

      json =
        conn
        |> auth(instructor)
        |> put("/api/invoices/#{invoice.id}", %{pay_off: true, invoice: invoice_params})
        |> json_response(200)

      invoice = preload_invoice(invoice)

      transaction = List.first(invoice.transactions)

      assert length(invoice.transactions) == 1

      assert not is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "completed"
      assert transaction.total == 25000
      assert transaction.type == "credit"
      assert transaction.payment_option == :cc
      assert transaction.paid_by_charge == 25000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    @tag :integration
    test "creates invoice when payment option is cc", %{conn: conn} do
      {student, _} = student_fixture() |> real_stripe_customer()
      invoice = invoice_fixture(%{payment_option: "cc"}, student)
      instructor = instructor_fixture()
      invoice_params = %{total_amount_due: 25000}

      json =
        conn
        |> auth(instructor)
        |> put("/api/invoices/#{invoice.id}", %{pay_off: true, invoice: invoice_params})
        |> json_response(200)

      invoice = preload_invoice(invoice)

      transaction = List.first(invoice.transactions)

      assert not is_nil(transaction.completed_at)
      assert not is_nil(transaction.stripe_charge_id)

      assert transaction.state == "completed"
      assert transaction.total == 25000
      assert transaction.type == "credit"
      assert transaction.payment_option == :cc
      assert transaction.paid_by_charge == 25000

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end
  end

  @tag :integration
  test "creates invoice from appointment", %{conn: conn} do
    appointment = appointment_fixture()
    instructor = instructor_fixture()

    json =
      conn
      |> auth(instructor)
      |> post("/api/invoices/from_appointment/#{appointment.id}")
      |> json_response(201)

    invoice = Repo.get_by(Invoice, user_id: appointment.user_id) |> preload_invoice

    assert invoice.total == 460
    assert invoice.tax_rate == 10
    assert invoice.total_tax == 46
    assert invoice.total_amount_due == 506
    assert Enum.count(invoice.line_items) == 2

    assert json == render_json(InvoiceView, "show.json", invoice: invoice)
  end

  def preload_invoice(invoice) do
    Repo.get(Invoice, invoice.id)
    |> Repo.preload([:user, :transactions, :line_items, :appointment], force: true)
  end
end
