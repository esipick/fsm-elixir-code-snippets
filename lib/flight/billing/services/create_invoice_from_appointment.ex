defmodule Flight.Billing.CreateInvoiceFromAppointment do
  import Ecto.Query, warn: false

  alias Flight.Scheduling.Appointment
  alias Flight.Repo
  alias Flight.Billing.{Invoice, CalculateInvoice}

  def run(appointment_id, params, school_context) do
    case fetch_invoice(appointment_id) do
      {:ok, invoice} ->
        {:ok, invoice}

      {:error, _} ->
        create_invoice_from_appointment(appointment_id, params, school_context)
    end
  end

  def fetch_invoice(appointment_id) do
    invoice =
      from(
        i in Invoice,
        where: i.appointment_id == ^appointment_id and i.archived == false,
        order_by: [desc: i.inserted_at]
      )
      |> limit(1)
      |> Repo.one()

    if invoice do
      {:ok, invoice}
    else
      {:error, nil}
    end
  end

  def create_invoice_from_appointment(appointment_id, params, school_context) do
    appointment =
      Repo.get(Appointment, appointment_id)
      |> Repo.preload([:user, :instructor_user, :aircraft])

    school = school(school_context)
    current_user = school_context.assigns.current_user

    invoice_payload = %{
      "school_id" => school.id,
      "appointment_id" => appointment.id,
      "user_id" => appointment.user_id,
      "payer_name" => payer_name_from(appointment),
      "date" => NaiveDateTime.to_date(appointment.end_at),
      "payment_option" => Map.get(params, "payment_option", "balance"),
      "line_items" => line_items_from(appointment, params, current_user)
    }

    case CalculateInvoice.run(invoice_payload, school_context) do
      {:ok, invoice_params} ->
        Flight.Billing.CreateInvoice.run(invoice_params, school_context)

      {:error, errors} ->
        {:error, errors}
    end
  end

  defp payer_name_from(appointment) do
    Flight.Accounts.User.full_name(appointment.user || appointment.instructor_user)
  end

  defp line_items_from(appointment, params, current_user) do
    duration = Timex.diff(appointment.end_at, appointment.start_at, :minutes) / 60.0

    [
      aircraft_item(appointment, duration, params, current_user),
      instructor_item(appointment, duration, current_user)
    ]
    |> Enum.filter(fn x -> x end)
  end

  def aircraft_item(appointment, quantity, params \\ %{}, current_user) do
    if appointment.aircraft do
      rate = appointment.aircraft.rate_per_hour
      hobbs_end = Map.get(params, "hobbs_time", nil)
      tach_end = Map.get(params, "tach_time", nil)

      %{
        "description" => "Flight Hours",
        "rate" => rate,
        "quantity" => quantity,
        "amount" => round(rate * quantity),
        "type" => :aircraft,
        "aircraft_id" => appointment.aircraft.id,
        "taxable" => true,
        "deductible" => false,
        "hobbs_tach_used" => !!(hobbs_end || tach_end),
        "hobbs_start" => appointment.aircraft.last_hobbs_time,
        "tach_start" => appointment.aircraft.last_tach_time,
        "hobbs_end" => hobbs_end,
        "tach_end" => tach_end,
        "creator_id" => current_user.id
      }
    end
  end

  def instructor_item(appointment, quantity, current_user) do
    if appointment.instructor_user do
      rate = appointment.instructor_user.billing_rate

      %{
        "description" => "Instructor Hours",
        "rate" => rate,
        "quantity" => quantity,
        "amount" => round(rate * quantity),
        "type" => :instructor,
        "instructor_user_id" => appointment.instructor_user.id,
        "taxable" => false,
        "deductible" => false,
        "creator_id" => current_user.id
      }
    end
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end
end
