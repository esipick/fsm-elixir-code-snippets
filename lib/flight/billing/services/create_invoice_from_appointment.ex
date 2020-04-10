defmodule Flight.Billing.CreateInvoiceFromAppointment do
  import Ecto.Query, warn: false

  alias Flight.Scheduling.Appointment
  alias Flight.Repo
  alias Flight.Billing.{Invoice, CalculateInvoice}

  def run(appointment_id, params, school_context) do
    invoice =
      from(i in Invoice,
        where: i.appointment_id == ^appointment_id,
        order_by: [desc: i.inserted_at]
      )
      |> limit(1)
      |> Repo.one()

    if invoice do
      {:ok, invoice}
    else
      create_invoice_from_appointment(appointment_id, params, school_context)
    end
  end

  def create_invoice_from_appointment(appointment_id, params, school_context) do
    appointment =
      Repo.get(Appointment, appointment_id) |> Repo.preload([:instructor_user, :aircraft])

    school = school(school_context)
    duration = Timex.diff(appointment.end_at, appointment.start_at, :hours)
    payment_option = Map.get(params, "payment_option", "balance")

    line_items =
      [
        aircraft_item(appointment, duration),
        instructor_item(appointment, duration)
      ]
      |> Enum.filter(fn x -> x end)

    {:ok, invoice_params} =
      CalculateInvoice.run(
        %{
          "school_id" => school.id,
          "appointment_id" => appointment.id,
          "user_id" => appointment.user_id,
          "date" => NaiveDateTime.to_date(appointment.end_at),
          "payment_option" => payment_option,
          "line_items" => line_items
        },
        school_context
      )

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
        "aircraft_id" => appointment.aircraft.id,
        "taxable" => true
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
        "instructor_user_id" => appointment.instructor_user.id,
        "taxable" => false
      }
    end
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end
end
