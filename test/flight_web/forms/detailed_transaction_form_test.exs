defmodule FlightWeb.API.DetailedTransactionFormTest do
  use Flight.DataCase

  import Flight.BillingFixtures

  alias Flight.Billing
  alias FlightWeb.API.DetailedTransactionForm
  alias FlightWeb.API.DetailedTransactionForm.{AircraftDetails, InstructorDetails}

  describe "form" do
    test "validates filled out data" do
      student = student_fixture()
      instructor = instructor_fixture()
      aircraft = aircraft_fixture()

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      attrs =
        detailed_transaction_form_attrs(student, instructor, appointment, aircraft, instructor)

      assert DetailedTransactionForm.changeset(%DetailedTransactionForm{}, attrs).valid?
    end

    test "to_transaction creates insertable transaction" do
      student = student_fixture()
      instructor = instructor_fixture(%{billing_rate: 7500, pay_rate: 3000})
      aircraft = aircraft_fixture(%{rate_per_hour: 120})

      appointment = appointment_fixture(%{}, student, instructor, aircraft)

      attrs =
        detailed_transaction_form_attrs(student, instructor, appointment, aircraft, instructor)

      {:ok, form} =
        %DetailedTransactionForm{}
        |> DetailedTransactionForm.changeset(attrs)
        |> Ecto.Changeset.apply_action(:insert)

      {transaction, instructor_line_item, instructor_details, aircraft_line_item,
       aircraft_details} = DetailedTransactionForm.to_transaction(form, :normal, instructor)

      assert transaction.state == "pending"
      assert transaction.user_id == attrs.user_id
      assert transaction.creator_user_id == attrs.creator_user_id
      assert transaction.total == aircraft_line_item.amount + instructor_line_item.amount

      assert instructor_details.instructor_user_id == attrs.instructor_details.instructor_id
      assert instructor_details.hour_tenths == attrs.instructor_details.hour_tenths
      assert instructor_details.billing_rate == instructor.billing_rate
      assert instructor_details.pay_rate == instructor.pay_rate

      assert instructor_line_item.instructor_user_id == attrs.instructor_details.instructor_id
      assert instructor_line_item.amount == Billing.instructor_cost!(instructor_details)

      assert aircraft_line_item.aircraft_id == attrs.aircraft_details.aircraft_id
      assert aircraft_line_item.amount == Billing.aircraft_cost!(aircraft_details)

      assert aircraft_details.aircraft_id == attrs.aircraft_details.aircraft_id
      assert aircraft_details.hobbs_start == attrs.aircraft_details.hobbs_start
      assert aircraft_details.hobbs_end == attrs.aircraft_details.hobbs_end
      assert aircraft_details.tach_start == attrs.aircraft_details.tach_start
      assert aircraft_details.tach_end == attrs.aircraft_details.tach_end
      assert aircraft_details.rate == 120
      assert aircraft_details.fee_percentage == 0.00
      assert aircraft_details.rate_type == "normal"

      assert Flight.Repo.insert!(transaction)
    end

    test "error if no instructor or aircraft" do
      appointment = appointment_fixture()

      attrs = %{
        user_id: 3,
        creator_user_id: 9,
        appointment_id: appointment.id,
        aircraft_details: nil,
        instructor_details: nil
      }

      changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, attrs)

      assert errors_on(changeset).aircraft_details

      refute changeset.valid?
    end

    test "error if no user_id or custom_user" do
      appointment = appointment_fixture()

      attrs = %{
        creator_user_id: 9,
        instructor_user_id: 4,
        appointment_id: appointment.id,
        aircraft_details: nil,
        instructor_details: %{
          instructor_id: 3,
          hour_tenths: 10
        }
      }

      changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, attrs)

      assert errors_on(changeset).user

      refute changeset.valid?
    end

    test "error if both user_id and custom_user" do
      appointment = appointment_fixture()

      attrs = %{
        user_id: 3,
        custom_user: %{
          first_name: "Foo",
          last_name: "Bar",
          email: "foo@bar.com"
        },
        creator_user_id: 9,
        appointment_id: appointment.id,
        aircraft_details: nil,
        source: "tok_visa",
        instructor_details: %{
          instructor_id: 3,
          hour_tenths: 10
        }
      }

      changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, attrs)

      assert errors_on(changeset).user

      refute changeset.valid?
    end
  end

  describe "aircraft_details" do
    test "fails if hobbs_end less than or equal to hobbs_start" do
      aircraft = aircraft_fixture()

      attrs = %{
        aircraft_id: aircraft.id,
        hobbs_start: aircraft.last_hobbs_time,
        hobbs_end: aircraft.last_hobbs_time,
        tach_start: aircraft.last_tach_time,
        tach_end: aircraft.last_tach_time + 10
      }

      changeset = AircraftDetails.changeset(%AircraftDetails{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset).hobbs_end
    end

    test "fails if hobbs_start is less than aircraft hobbs_start" do
      aircraft = aircraft_fixture()

      attrs = %{
        aircraft_id: aircraft.id,
        hobbs_start: aircraft.last_hobbs_time - 1,
        hobbs_end: aircraft.last_hobbs_time + 10,
        tach_start: aircraft.last_tach_time,
        tach_end: aircraft.last_tach_time + 10
      }

      changeset = AircraftDetails.changeset(%AircraftDetails{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset).hobbs_start
    end

    test "fails if tach_end less than or equal to tach_start" do
      aircraft = aircraft_fixture()

      attrs = %{
        aircraft_id: aircraft.id,
        hobbs_start: aircraft.last_hobbs_time,
        hobbs_end: aircraft.last_hobbs_time + 10,
        tach_start: aircraft.last_tach_time,
        tach_end: aircraft.last_tach_time
      }

      changeset = AircraftDetails.changeset(%AircraftDetails{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset).tach_end
    end

    test "fails if tach_start is less than aircraft tach_start" do
      aircraft = aircraft_fixture()

      attrs = %{
        aircraft_id: aircraft.id,
        hobbs_start: aircraft.last_hobbs_time,
        hobbs_end: aircraft.last_hobbs_time + 10,
        tach_start: aircraft.last_tach_time - 1,
        tach_end: aircraft.last_tach_time + 10
      }

      changeset = AircraftDetails.changeset(%AircraftDetails{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset).tach_start
    end
  end

  describe "instructor_details" do
    test "fails if hour tenths less than or equal to zero" do
      attrs = %{
        instructor_id: 3,
        hour_tenths: 0
      }

      changeset = InstructorDetails.changeset(%InstructorDetails{}, attrs)

      refute changeset.valid?

      assert errors_on(changeset).hour_tenths
    end
  end
end
