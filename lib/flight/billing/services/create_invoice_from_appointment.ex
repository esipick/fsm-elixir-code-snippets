defmodule Flight.Billing.CreateInvoiceFromAppointment do
  alias Flight.Scheduling.Appointment
  alias Flight.Repo

  def run(appointment_id, school_context) do
    appointment =
      Repo.get(Appointment, appointment_id) |> Repo.preload([:instructor_user, :aircraft])

    school = school(school_context)
    duration = Timex.diff(appointment.end_at, appointment.start_at, :hours)

    line_items =
      [
        aircraft_item(appointment, duration),
        instructor_item(appointment, duration)
      ]
      |> Enum.filter(fn x -> x end)

    total = Enum.map(line_items, fn x -> x["amount"] end) |> Enum.sum()
    total_tax = round(total * school.sales_tax / 100)

    invoice_params = %{
      "school_id" => school.id,
      "appointment_id" => appointment.id,
      "user_id" => appointment.user_id,
      "date" => NaiveDateTime.to_date(appointment.end_at),
      "payment_option" => "balance",
      "total" => total,
      "tax_rate" => school.sales_tax,
      "total_tax" => total_tax,
      "total_amount_due" => total + total_tax,
      "line_items" => line_items
    }

    Flight.Billing.CreateInvoice.run(invoice_params, school_context)
  end

  def aircraft_item(appointment, quantity) do
    if appointment.aircraft do
      rate = appointment.aircraft.rate_per_hour

      %{
        "description" => "Flight Hours",
        "rate" => rate,
        "quantity" => quantity,
        "amount" => rate * quantity,
        "type" => :aircraft,
        "aircraft_id" => appointment.aircraft.id
      }
    end
  end

  def instructor_item(appointment, quantity) do
    if appointment.instructor_user do
      rate = appointment.instructor_user.billing_rate

      %{
        "description" => "Instructor Hours",
        "rate" => rate,
        "quantity" => quantity,
        "amount" => rate * quantity,
        "type" => :instructor,
        "instructor_user_id" => appointment.instructor_user.id
      }
    end
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end
end
