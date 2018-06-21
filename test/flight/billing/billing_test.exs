defmodule Flight.BillingTest do
  use Flight.DataCase

  import Flight.AccountsFixtures
  import Flight.SchedulingFixtures
  import Flight.BillingFixtures

  alias Flight.Billing
  alias Flight.Billing.{Transaction}

  describe "create_transaction_from_detailed_form/1" do
    test "creates transaction and all sub resources" do
      student = student_fixture()
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      form =
        detailed_transaction_form_fixture(student, instructor, appointment, aircraft, instructor)

      assert {:ok, transaction} = Billing.create_transaction_from_detailed_form(form)

      assert aircraft_line_item =
               Flight.Repo.get_by(
                 Flight.Billing.TransactionLineItem,
                 transaction_id: transaction.id,
                 aircraft_id: aircraft.id
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
    end
  end

  describe "aircraft_cost/3" do
    test "correct rate is calculated" do
      aircraft = aircraft_fixture(%{rate_per_hour: 75})

      amount = (75 * 1.1 * 1.2 * 100) |> trunc()

      assert {:ok, ^amount} = Billing.aircraft_cost(aircraft, 3333, 3345, 0.1)
    end

    test "0 duration is an error" do
      aircraft = aircraft_fixture(%{rate_per_hour: 75})

      assert {:error, :invalid_hobbs_interval} = Billing.aircraft_cost(aircraft, 3333, 3333, 0.1)
    end

    test "bang version returns only value" do
      aircraft = aircraft_fixture(%{rate_per_hour: 75})

      {:ok, amount} = Billing.aircraft_cost(aircraft, 3333, 3345, 0.1)

      assert Billing.aircraft_cost!(aircraft, 3333, 3345, 0.1) == amount
    end
  end

  describe "instructor_cost/3" do
    test "correct rate is calculated" do
      instructor = instructor_fixture(%{billing_rate: 75})

      amount = (75 * 1.2 * 100) |> trunc()

      assert {:ok, ^amount} = Billing.instructor_cost(instructor, 12)
    end

    test "0 duration is an error" do
      instructor = instructor_fixture(%{billing_rate: 75})

      assert {:error, :invalid_hours} = Billing.instructor_cost(instructor, 0)
    end

    test "bang version returns only value" do
      instructor = instructor_fixture(%{billing_rate: 75})

      {:ok, amount} = Billing.instructor_cost(instructor, 12)

      assert Billing.instructor_cost!(instructor, 12) == amount
    end
  end

  describe "update_balance/2" do
    test "removes amount from balance" do
      user = user_fixture(%{balance: 5000})

      assert {:ok, user} = Billing.update_balance(user, -3000)

      assert user.balance == 2000
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
      refute transaction.paid_by_balance

      assert line_item.amount == 3000
      assert line_item.transaction_id == transaction.id
      assert line_item.description == "Added funds to balance."
    end
  end
end
