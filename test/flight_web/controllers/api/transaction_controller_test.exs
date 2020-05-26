defmodule FlightWeb.API.TransactionControllerTest do
  use FlightWeb.ConnCase

  import Flight.BillingFixtures

  alias FlightWeb.API.TransactionView

  describe "POST /api/transactions" do
    ###
    # Detailed
    ###

    @tag :integration
    test "creates pending detailed transaction", %{conn: conn} do
      {student, _} = student_fixture() |> real_stripe_customer(false)
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

    @tag :integration
    test "returns correct error when hobbs time is invalid", %{conn: conn} do
      {student, _} = student_fixture() |> real_stripe_customer(false)
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      params =
        detailed_transaction_form_attrs(student, instructor, appointment, aircraft, instructor)

      aircraft_details =
        Map.put(params[:aircraft_details], :hobbs_start, aircraft.last_hobbs_time - 1)

      params = Map.merge(params, %{aircraft_details: aircraft_details})

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions", %{detailed: params})
        |> json_response(400)

      assert json == %{
               "human_errors" => [
                 "Aircraft details Hobbs start must be greater than current aircraft hobbs start (40.0)"
               ]
             }
    end

    @tag :integration
    test "creates completed detailed transaction if user has enough in their balance", %{
      conn: conn
    } do
      student = student_fixture(%{balance: 3_000_000})
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

      assert transaction.state == "completed"
      assert transaction.paid_by_balance
      refute transaction.paid_by_charge

      student = Flight.Repo.get(Flight.Accounts.User, student.id)

      assert student.balance == 3_000_000 - transaction.total

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "creates completed detailed cash transaction starting with zero balance", %{
      conn: conn
    } do
      student = student_fixture(%{balance: 0})
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()
      source = "cash"

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      params =
        detailed_transaction_form_attrs(
          student,
          instructor,
          appointment,
          aircraft,
          instructor,
          source
        )

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions", %{detailed: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"

      assert transaction.paid_by_cash
      refute transaction.paid_by_balance
      refute transaction.paid_by_charge

      student = Flight.Repo.get(Flight.Accounts.User, student.id)

      assert transaction.total == transaction.paid_by_cash
      assert student.balance == 0

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "creates completed detailed transaction as student, taken from balance", %{conn: conn} do
      student = student_fixture(%{balance: 3_000_000})
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

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
    test "creates completed detailed transaction as student, charged to card", %{conn: conn} do
      {student, card} = student_fixture(%{balance: 0}) |> real_stripe_customer()
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

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

    @tag :integration
    test "creates completed detailed transaction as instructor, charged to custom user", %{
      conn: conn
    } do
      real_stripe_account(default_school_fixture())
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      params =
        detailed_transaction_form_attrs(nil, instructor, nil, aircraft, nil)
        |> Map.delete(:user_id)
        |> Map.merge(%{
          custom_user: %{
            first_name: "Jackson",
            last_name: "Jill",
            email: "jackson@jill.com"
          },
          source: "tok_visa"
        })

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions", %{detailed: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(
                 Flight.Billing.Transaction,
                 email: "jackson@jill.com"
               )
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"
      assert transaction.paid_by_charge == transaction.total
      assert transaction.stripe_charge_id
      refute transaction.user_id

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "creates completed detailed cash transaction as instructor, charged to custom user", %{
      conn: conn
    } do
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()
      source = "cash"

      params =
        detailed_transaction_form_attrs(nil, instructor, nil, aircraft, nil, source)
        |> Map.delete(:user_id)
        |> Map.merge(%{
          custom_user: %{
            first_name: "Jackson",
            last_name: "Jill",
            email: "jackson@jill.com"
          }
        })

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions", %{detailed: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(
                 Flight.Billing.Transaction,
                 email: "jackson@jill.com"
               )
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"

      assert transaction.paid_by_cash == transaction.total

      assert transaction.paid_by_cash
      refute transaction.paid_by_charge
      refute transaction.paid_by_charge

      refute transaction.stripe_charge_id
      refute transaction.user_id

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "returns stripe errors", %{conn: conn} do
      {student, nil} = student_fixture(%{balance: 0}) |> real_stripe_customer(false)

      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      params =
        detailed_transaction_form_attrs(student, student, appointment, aircraft, nil)
        |> Map.put(:source, "garbage")

      json =
        conn
        |> auth(student)
        |> post("/api/transactions", %{detailed: params})
        |> json_response(400)

      assert List.first(json["human_errors"]) =~ "There was an error"
    end

    ###
    # Custom
    ###

    @tag :integration
    test "creates pending custom transaction", %{conn: conn} do
      {student, _} = student_fixture() |> real_stripe_customer(false)
      instructor = instructor_fixture()

      params = custom_transaction_form_attrs(%{}, student, instructor)

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions", %{custom: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "pending"

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "creates custom transaction for custom user", %{conn: conn} do
      real_stripe_account(default_school_fixture())
      instructor = instructor_fixture()

      params =
        custom_transaction_form_attrs(%{}, nil, instructor)
        |> Map.delete(:user_id)
        |> Map.merge(%{
          custom_user: %{
            first_name: "j",
            last_name: "t",
            email: "justin@timberlake.com"
          },
          source: "tok_visa"
        })

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions", %{custom: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, email: "justin@timberlake.com")
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"
      refute transaction.user_id

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "creates completed custom transaction as student, taken from balance", %{conn: conn} do
      student = student_fixture(%{balance: 3_000_000})

      params = custom_transaction_form_attrs(%{amount: 40000}, student, student)

      json =
        conn
        |> auth(student)
        |> post("/api/transactions", %{custom: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"
      assert transaction.paid_by_balance == 40000
      assert transaction.total == 40000

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "creates completed custom cash transaction starting with zero balance", %{conn: conn} do
      student = student_fixture(%{balance: 0})
      instructor = instructor_fixture()
      source = "cash"
      amount = 20000

      params =
        custom_transaction_form_attrs(
          %{amount: amount, source: source},
          student,
          instructor
        )

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions", %{custom: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"

      assert transaction.paid_by_cash
      refute transaction.paid_by_balance
      refute transaction.paid_by_charge

      assert transaction.total == amount
      assert transaction.total == transaction.paid_by_cash

      student = Flight.Repo.get(Flight.Accounts.User, student.id)

      assert student.balance == 0

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "rejects non instructor or admin attempt to create a custom cash transaction", %{
      conn: conn
    } do
      student = student_fixture()
      instructor = instructor_fixture()
      source = "cash"
      amount = 20000

      params =
        custom_transaction_form_attrs(
          %{amount: amount, source: source},
          student,
          instructor
        )

      conn
      |> auth(student)
      |> post("/api/transactions", %{custom: params})
      |> json_response(401)

      transaction =
        Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
        |> Flight.Repo.preload([:line_items, :user, :creator_user])

      refute transaction
    end

    @tag :integration
    test "creates completed custom transaction as student, charged to card", %{conn: conn} do
      {student, card} = student_fixture(%{balance: 0}) |> real_stripe_customer()

      params =
        custom_transaction_form_attrs(%{}, student, student)
        |> Map.put(:source, card.id)

      json =
        conn
        |> auth(student)
        |> post("/api/transactions", %{custom: params})
        |> json_response(201)

      assert transaction =
               Flight.Repo.get_by(Flight.Billing.Transaction, user_id: student.id)
               |> Flight.Repo.preload([:line_items, :user, :creator_user])

      assert transaction.state == "completed"
      assert transaction.paid_by_charge == transaction.total
      assert transaction.stripe_charge_id

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "401 if other student", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      params = custom_transaction_form_attrs(%{}, student, instructor)

      conn
      |> auth(student_fixture())
      |> post("/api/transactions", %{custom: params})
      |> response(401)
    end

    @tag :skip
    test "401 if student tries to make instructor the creator", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      params = custom_transaction_form_attrs(%{}, student, instructor)

      conn
      |> auth(student)
      |> post("/api/transactions", %{custom: params})
      |> response(401)
    end

    @tag :integration
    test "401 if student tries to make instructor the user", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      params = custom_transaction_form_attrs(%{}, instructor, student)

      conn
      |> auth(student)
      |> post("/api/transactions", %{custom: params})
      |> response(401)
    end

    @tag :skip
    test "401 if instructor creates on behalf of other instructor", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      params = custom_transaction_form_attrs(%{}, student, instructor)

      conn
      |> auth(instructor_fixture())
      |> post("/api/transactions", %{custom: params})
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

      transaction = Flight.Billing.get_transaction(json["data"]["id"], user)

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
    @tag :integration
    test "renders detailed preview", %{conn: conn} do
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

      {transaction, instructor_line_item, _, aircraft_line_item, _} =
        detailed_transaction_form_fixture(student, instructor, appointment, aircraft, instructor)
        |> FlightWeb.API.DetailedTransactionForm.to_transaction(:normal, student)

      assert json ==
               render_json(
                 TransactionView,
                 "preview.json",
                 transaction: transaction,
                 line_items: [instructor_line_item, aircraft_line_item]
               )
    end

    @tag :integration
    test "renders custom preview", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      params = custom_transaction_form_attrs(%{}, student, instructor)

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions/preview", %{custom: params})
        |> json_response(200)

      {transaction, line_item} =
        custom_transaction_form_fixture(%{}, student, instructor)
        |> FlightWeb.API.CustomTransactionForm.to_transaction(student)

      assert json ==
               render_json(
                 TransactionView,
                 "preview.json",
                 transaction: transaction,
                 line_items: [line_item]
               )
    end

    @tag :integration
    test "renders preview for only one", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      params = detailed_transaction_form_attrs(student, instructor, nil, nil, instructor)

      json =
        conn
        |> auth(instructor)
        |> post("/api/transactions/preview", %{detailed: params})
        |> json_response(200)

      {transaction, instructor_line_item, _, nil, _} =
        detailed_transaction_form_fixture(student, instructor, nil, nil, instructor)
        |> FlightWeb.API.DetailedTransactionForm.to_transaction(:normal, student)

      assert json ==
               render_json(
                 TransactionView,
                 "preview.json",
                 transaction: transaction,
                 line_items: [instructor_line_item]
               )
    end
  end

  describe "GET /api/transactions" do
    @tag :integration
    test "returns transactions for user_id", %{conn: conn} do
      student = student_fixture()

      transaction1 =
        transaction_fixture(%{}, student)
        |> TransactionView.preload()

      _ = transaction_fixture(%{}, student_fixture())

      json =
        conn
        |> auth(student)
        |> get("/api/transactions?user_id=#{student.id}")
        |> json_response(200)

      assert json == render_json(TransactionView, "index.json", transactions: [transaction1])
    end

    @tag :integration
    test "returns filtered transactions by user name", %{conn: conn} do
      student = student_fixture(%{first_name: "Adrian", last_name: "Nairda"})
      instructor = instructor_fixture()

      transaction1 =
        transaction_fixture(%{}, student)
        |> TransactionView.preload()

      _ = transaction_fixture(%{}, student_fixture(%{email: "adrian@nairda.com"}))

      json =
        conn
        |> auth(instructor)
        |> get("/api/transactions?search_term=adr")
        |> json_response(200)

      assert json == render_json(TransactionView, "index.json", transactions: [transaction1])
    end

    @tag :integration
    test "returns filtered transactions by total", %{conn: conn} do
      instructor = instructor_fixture()

      transaction1 = transaction_fixture(%{total: 4932}) |> TransactionView.preload()
      _ = transaction_fixture(%{})

      json =
        conn
        |> auth(instructor)
        |> get("/api/transactions?search_term=932")
        |> json_response(200)

      assert json == render_json(TransactionView, "index.json", transactions: [transaction1])
    end

    @tag :integration
    test "401 if trying to request transactions for other users", %{conn: conn} do
      student = student_fixture()

      conn
      |> auth(student_fixture())
      |> get("/api/transactions?user_id=#{student.id}")
      |> response(401)
    end
  end

  describe "GET /api/transactions/:id" do
    @tag :integration
    test "returns transaction for user", %{conn: conn} do
      student = student_fixture()

      transaction =
        transaction_fixture(%{}, student)
        |> TransactionView.preload()

      json =
        conn
        |> auth(student)
        |> get("/api/transactions/#{transaction.id}")
        |> json_response(200)

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "returns transaction for creator", %{conn: conn} do
      instructor = instructor_fixture()

      transaction =
        transaction_fixture(%{}, student_fixture(), instructor)
        |> TransactionView.preload()

      json =
        conn
        |> auth(instructor)
        |> get("/api/transactions/#{transaction.id}")
        |> json_response(200)

      assert json == render_json(TransactionView, "show.json", transaction: transaction)
    end

    @tag :integration
    test "401 if trying to request transaction for other users", %{conn: conn} do
      student = student_fixture()
      transaction = transaction_fixture(%{}, student, student)

      conn
      |> auth(student_fixture())
      |> get("/api/transactions/#{transaction.id}")
      |> response(401)
    end
  end

  describe "POST /api/transactions/preferred_payment_method" do
    @tag :integration
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

    @tag :integration
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
