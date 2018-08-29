defmodule Flight.ReportsTest do
  use Flight.DataCase

  describe "student_report" do
    test "returns correct results" do
      {student, _} = student_fixture(%{balance: 30_000_000}) |> real_stripe_customer()

      IO.inspect(student.id)

      utc_now = NaiveDateTime.utc_now()

      appointment =
        appointment_fixture(
          %{
            start_at: utc_now,
            end_at: Timex.shift(utc_now, hours: 2)
          },
          student
        )

      appointment_fixture(
        %{
          start_at: utc_now,
          end_at: Timex.shift(utc_now, hours: 2)
        },
        student
      )

      {:ok, transaction} =
        detailed_transaction_form_fixture(
          student,
          instructor_fixture(),
          nil,
          aircraft_fixture(),
          instructor_fixture()
        )

      IO.inspect(transaction)

      now = Date.utc_today()

      report =
        Flight.Reports.student_report(
          Timex.shift(appointment.start_at, days: -1),
          Timex.shift(appointment.start_at, days: 1),
          student
        )

      IO.inspect(report.rows)

      assert Enum.count(report.rows) == 1

      report_student = List.first(report.rows)

      assert Enum.at(report_student, 0) == "#{student.first_name} #{student.last_name}"
      assert Enum.at(report_student, 1) == 2
      assert Enum.at(report_student, 2) == 32
      assert Enum.at(report_student, 3) == 23
      assert Enum.at(report_student, 6) == 17634
    end
  end

  describe "num_appointments/2" do
    test "returns correct number of appointments" do
      student = student_fixture()

      appointment1 = appointment_fixture(%{}, student)
      appointment2 = appointment_fixture(%{}, student)

      assert Flight.Reports.num_appointments(student, %{
               student.id => [appointment1, appointment2]
             }) == 2
    end
  end

  describe "time_flown/2" do
    test "returns correct time" do
      {transaction, instructor_line_item, instructor_details, aircraft_line_item,
       aircraft_details} =
        detailed_transaction_form_fixture()
        |> FlightWeb.API.DetailedTransactionForm.to_transaction(:normal, default_school_fixture())
        
      now = NaiveDateTime.utc_now()

      transaction = %{transaction | state: "completed", completed_at: now}
    end
  end
end
