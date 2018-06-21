defmodule FlightWeb.API.TransactionControllerTest do
  use FlightWeb.ConnCase

  import Flight.BillingFixtures

  alias FlightWeb.API.TransactionView

  describe "POST /api/transactions" do
    test "creates pending transaction", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      params =
        detailed_transaction_form_attrs(student, instructor, appointment, aircraft, instructor)

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions", %{detailed: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "pending"

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    test "creates completed transaction as student, taken from balance", %{conn: conn} do
      student = student_fixture(%{balance: 3_000_000})
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{instructor_user_id: nil}, student, instructor, aircraft)

      params = detailed_transaction_form_attrs(student, student, appointment, aircraft, nil)

      json =
        conn
        |> auth(student)
        |> post("/api/transactions", %{detailed: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"
      assert transaction.paid_by_balance == transaction.total

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "creates completed transaction as student, charged to card", %{conn: conn} do
      {student, card} = student_fixture(%{balance: 0}) |> real_stripe_customer()
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{instructor_user_id: nil}, student, instructor, aircraft)

      params =
        detailed_transaction_form_attrs(student, student, appointment, aircraft, nil)
        |> Map.put(:source, card.id)

      json =
        conn
        |> auth(student)
        |> post("/api/transactions", %{detailed: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"
      assert transaction.paid_by_charge == transaction.total
      assert transaction.stripe_charge_id

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    test "401 if other student", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      params =
        detailed_transaction_form_attrs(student, instructor, appointment, aircraft, instructor)

      conn
      |> auth(student_fixture())
      |> post("/api/transactions", %{detailed: params})
      |> response(401)
    end
  end

  describe "POST /api/transactions add_funds" do
    @tag :integration
    test "adds funds", %{conn: conn} do
      {user, card} = student_fixture(%{balance: 300}) |> real_stripe_customer()

      assert user.balance == 300

      params = %{
        add_funds: %{
          user_id: user.id,
          source: card.id,
          amount: 10000
        }
      }

      json =
        conn
        |> auth(user)
        |> post("/api/transactions", params)
        |> json_response(201)

      transaction = Flight.Billing.get_transaction(json["data"]["id"])

      assert json ==
               render_json(
                 TransactionView,
                 "show.json",
                 transaction: FlightWeb.API.TransactionController.render_preloads(transaction)
               )

      user = Flight.Repo.get(Flight.Accounts.User, user.id)

      assert user.balance == 10300
    end
  end

  describe "POST /api/transactions/preview" do
    test "renders preview", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      params =
        detailed_transaction_form_attrs(student, instructor, appointment, aircraft, instructor)

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions/preview", %{detailed: params})
        |> json_response(200)

      {transaction, instructor_line_item, aircraft_line_item, _} =
        detailed_transaction_form_fixture(student, instructor, appointment, aircraft, instructor)
        |> FlightWeb.API.DetailedTransactionForm.to_transaction()

      assert json ==
               render_json(
                 TransactionView,
                 "preview.json",
                 transaction: transaction,
                 instructor_line_item: instructor_line_item,
                 aircraft_line_item: aircraft_line_item
               )
    end

    test "renders preview for only one", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      params = detailed_transaction_form_attrs(student, instructor, nil, nil, instructor)

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions/preview", %{detailed: params})
        |> json_response(200)

      {transaction, instructor_line_item, nil, _} =
        detailed_transaction_form_fixture(student, instructor, nil, nil, instructor)
        |> FlightWeb.API.DetailedTransactionForm.to_transaction()

      assert json ==
               render_json(
                 TransactionView,
                 "preview.json",
                 transaction: transaction,
                 instructor_line_item: instructor_line_item,
                 aircraft_line_item: nil
               )
    end
  end

  describe "GET /api/transactions" do
    test "returns transactions for user_id", %{conn: conn} do
      student = student_fixture()

      transaction1 =
        transaction_fixture(%{}, student)
        |> Flight.Repo.preload([:line_items, :user, :creator_user])

      _ = transaction_fixture(%{}, student_fixture())

      json =
        conn
        |> auth(student)
        |> get("/api/transactions?user_id=#{student.id}")
        |> json_response(200)

      assert json == render_json(TransactionView, "index.json", transactions: [transaction1])
    end

    test "401 if trying to request transactions for other users", %{conn: conn} do
      student = student_fixture()

      conn
      |> auth(student_fixture())
      |> get("/api/transactions?user_id=#{student.id}")
      |> response(401)
    end
  end

  describe "POST /api/transactions/preferred_payment_method" do
    test "returns balance", %{conn: conn} do
      user = student_fixture(%{balance: 30000})

      json =
        conn
        |> auth(user)
        |> post("/api/transactions/preferred_payment_method", %{amount: 20000})
        |> json_response(200)

      assert json ==
               render_json(TransactionView, "preferred_payment_method.json", method: "balance")
    end

    test "returns charge", %{conn: conn} do
      user = student_fixture(%{balance: 10000})

      json =
        conn
        |> auth(user)
        |> post("/api/transactions/preferred_payment_method", %{amount: 20000})
        |> json_response(200)

      assert json ==
               render_json(TransactionView, "preferred_payment_method.json", method: "charge")
    end
  end
end