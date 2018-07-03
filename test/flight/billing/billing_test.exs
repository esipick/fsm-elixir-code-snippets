defmodule Flight.BillingTest do
  use Flight.DataCase

  import Flight.AccountsFixtures
  import Flight.SchedulingFixtures
  import Flight.BillingFixtures

  alias Flight.Billing
  alias Flight.Billing.{Transaction}
  alias Flight.Scheduling.{Aircraft}

  describe "create_transaction_from_detailed_form/1" do
    test "creates transaction and all sub resources" do
      student = student_fixture()
      instructor = instructor_fixture()
      aircraft = aircraft_fixture(%{last_hobbs_time: 0, last_tach_time: 0})

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      form =
        detailed_transaction_form_fixture(student, instructor, appointment, aircraft, instructor)

      form = %{
        form
        | aircraft_details: %{
            form.aircraft_details
            | hobbs_start: 2003,
              hobbs_end: 2011,
              tach_start: 3003,
              tach_end: 3019
          }
      }

      assert {:ok, transaction} = Billing.create_transaction_from_detailed_form(form)

      assert aircraft_line_item =
               Flight.Repo.get_by(
                 Flight.Billing.TransactionLineItem,
                 transaction_id: transaction.id,
                 aircraft_id: aircraft.id
               )

      assert instructor_line_item =
               Flight.Repo.get_by(
                 Flight.Billing.TransactionLineItem,
                 transaction_id: transaction.id,
                 instructor_user_id: instructor.id
               )

      assert Flight.Repo.get_by(
               Flight.Billing.TransactionLineItem,
               transaction_id: transaction.id,
               instructor_user_id: instructor.id
             )

      assert Flight.Repo.get_by(
               Flight.Billing.AircraftLineItemDetail,
               transaction_line_item_id: aircraft_line_item.id
             )

      assert Flight.Repo.get_by(
               Flight.Billing.InstructorLineItemDetail,
               transaction_line_item_id: instructor_line_item.id
             )

      assert aircraft = Flight.Repo.get!(Aircraft, form.aircraft_details.aircraft_id)
      assert aircraft.last_hobbs_time == 2011
      assert aircraft.last_tach_time == 3019

      assert appointment = Flight.Repo.get!(Flight.Scheduling.Appointment, form.appointment_id)
      assert appointment.transaction_id == transaction.id
    end
  end

  describe "create_transaction_from_custom_form/1" do
    test "creates transaction and all sub resources" do
      student = student_fixture()
      instructor = instructor_fixture()

      form =
        custom_transaction_form_fixture(
          %{amount: 3721, description: "This is my jam"},
          student,
          instructor
        )

      assert {:ok, transaction} = Billing.create_transaction_from_custom_form(form)

      assert line_item =
               Flight.Repo.get_by(
                 Flight.Billing.TransactionLineItem,
                 transaction_id: transaction.id
               )

      assert line_item.description == "This is my jam"
      assert line_item.amount == 3721
      assert transaction.total == line_item.amount
      assert transaction.user_id == student.id
      assert transaction.creator_user_id == instructor.id
      assert transaction.state == "pending"
      refute transaction.completed_at
      assert transaction.type == "debit"
    end

    @tag :integration
    test "creates transaction as completed if creator == user" do
      {student, card} = student_fixture() |> real_stripe_customer()

      form = custom_transaction_form_fixture(%{source: card.id}, student, student)

      assert {:ok, transaction} = Billing.create_transaction_from_custom_form(form)

      assert transaction.state == "completed"
      assert transaction.completed_at
    end
  end

  describe "aircraft_cost/3" do
    test "correct rate is calculated for line item detail" do
      detail = %Flight.Billing.AircraftLineItemDetail{
        hobbs_start: 3333,
        hobbs_end: 3345,
        rate: 75,
        fee_percentage: 0.1
      }

      assert Billing.aircraft_cost(detail) == Billing.aircraft_cost(3333, 3345, 75, 0.1)
    end

    test "correct rate is calculated for normal_rate" do
      amount = (75 * 1.1 * 1.2 * 100) |> trunc()
      assert {:ok, ^amount} = Billing.aircraft_cost(3333, 3345, 75, 0.1)
    end

    test "0 duration is an error" do
      assert {:error, :invalid_hobbs_interval} = Billing.aircraft_cost(3333, 3333, 25, 0.1)
    end

    test "bang version returns only value" do
      {:ok, amount} = Billing.aircraft_cost(3333, 3345, 25, 0.1)
      assert Billing.aircraft_cost!(3333, 3345, 25, 0.1) == amount
    end
  end

  describe "instructor_cost/3" do
    test "instructor detail performs correct math" do
      detail = %Flight.Billing.InstructorLineItemDetail{
        hour_tenths: 15,
        billing_rate: 7500
      }

      assert Billing.instructor_cost(detail) == Billing.instructor_cost(7500, 15)
    end

    test "correct rate is calculated" do
      amount = (7500 * 1.2) |> trunc()

      assert {:ok, ^amount} = Billing.instructor_cost(7500, 12)
    end

    test "0 duration is an error" do
      assert {:error, :invalid_hours} = Billing.instructor_cost(75, 0)
    end

    test "bang version returns only value" do
      {:ok, amount} = Billing.instructor_cost(75, 12)

      assert Billing.instructor_cost!(75, 12) == amount
    end
  end

  describe "update_balance/2" do
    test "removes amount from balance" do
      user = user_fixture(%{balance: 5000})

      assert {:ok, user} = Billing.update_balance(user, -3000)

      assert user.balance == 2000
    end
  end

  describe "rate_type_for_form/1" do
    test "normal rate if user can't afford block rate total under their balance" do
      student = student_fixture(%{balance: 10})

      form =
        detailed_transaction_form_fixture(student, student)
        |> Map.put(:total, 30100)

      assert Billing.rate_type_for_form(form) == :normal
    end

    test "block rate if user can afford the block rate" do
      student = student_fixture(%{balance: 3_000_000})

      form = detailed_transaction_form_fixture(student, student)

      assert Billing.rate_type_for_form(form) == :block
    end
  end

  describe "approve_transaction/2" do
    test "approve deducts from balance" do
      user = user_fixture(%{balance: 5000})
      transaction = transaction_fixture(%{total: 3000}, user)

      refute transaction.completed_at

      assert {:ok, %Transaction{state: "completed", paid_by_balance: 3000} = transaction} =
               Billing.approve_transaction(transaction)

      assert transaction.completed_at
      assert transaction.type == "debit"

      user = Flight.Repo.get(Flight.Accounts.User, transaction.user.id)

      assert user.balance == 2000
    end

    @tag :integration
    test "approve charges card" do
      {user, card} = user_fixture(%{balance: 0}) |> real_stripe_customer()
      transaction = transaction_fixture(%{total: 3000}, user)

      refute transaction.completed_at

      assert {:ok, %Transaction{} = transaction} =
               Billing.approve_transaction(transaction, card.id)

      assert transaction.completed_at
      assert transaction.state == "completed"
      assert transaction.type == "debit"
      assert transaction.paid_by_charge == 3000
      refute transaction.paid_by_balance
    end
  end

  describe "add_funds_by_charge/2" do
    @tag :integration
    test "adds funds to user and creates transaction" do
      {user, card} = student_fixture() |> real_stripe_customer()

      assert {:ok, {user, transaction}} = Billing.add_funds_by_charge(user, user, 3000, card.id)

      assert Enum.count(transaction.line_items) == 1

      line_item = List.first(transaction.line_items)

      assert user.balance == 3000
      assert transaction.total == 3000
      assert transaction.type == "credit"
      assert transaction.paid_by_charge == 3000
      assert transaction.user_id == user.id
      assert transaction.creator_user_id == user.id
      assert transaction.stripe_charge_id
      refute transaction.paid_by_balance

      assert line_item.amount == 3000
      assert line_item.transaction_id == transaction.id
      assert line_item.description == "Added funds to balance."
    end
  end

  describe "parse_amount" do
    test "passes for valid string" do
      assert {:ok, 30032} = Billing.parse_amount("300.32")
    end

    test "passes for valid string with extra digits" do
      assert {:ok, 30032} = Billing.parse_amount("300.329999")
    end

    test "errors for invalid string" do
      assert {:error, :invalid} = Billing.parse_amount("sodifjs")
    end
  end

  describe "add_funds_by_credit/2" do
    test "adds funds to user and creates transaction" do
      user = student_fixture()
      admin = admin_fixture()

      assert {:ok, {user, transaction}} = Billing.add_funds_by_credit(user, admin, 3000)

      assert Enum.count(transaction.line_items) == 1

      user = Flight.Repo.get(Flight.Accounts.User, user.id)
      line_item = List.first(transaction.line_items)

      assert user.balance == 3000
      assert transaction.total == 3000
      assert transaction.type == "credit"
      refute transaction.paid_by_charge
      refute transaction.paid_by_balance
      assert transaction.user_id == user.id
      assert transaction.creator_user_id == admin.id
      refute transaction.stripe_charge_id

      assert line_item.amount == 3000
      assert line_item.transaction_id == transaction.id
      assert line_item.description == "Added funds to balance."
    end
  end
end
