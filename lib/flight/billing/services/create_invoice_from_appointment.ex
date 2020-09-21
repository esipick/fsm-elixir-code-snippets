defmodule Flight.Billing.CreateInvoiceFromAppointment do
  import Ecto.Query, warn: false

  alias Flight.Scheduling.Appointment
  alias Flight.Repo
  alias Flight.Billing.{Invoice, CalculateInvoice, CreateInvoice, UpdateInvoice}

  @invoice_line_item_excluded_types ~w(aircraft instructor room)a
  @invoice_line_item_fields ~w(id description rate amount quantity creator_id type taxable deductible)a

  def run(appointment_id, params, school_context) do
    appointment = get_appointment(appointment_id)

    case fetch_invoice(appointment.id) do
      {:ok, invoice} ->
        sync_invoice(appointment, invoice, params, school_context)

      {:error, _} ->
        create_invoice_from_appointment(appointment, params, school_context)
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
      |> Repo.preload([:line_items])

    if invoice do
      {:ok, invoice}
    else
      {:error, nil}
    end
  end

  def sync_invoice(appointment, invoice, params, school_context) do
    if invoice.status == :paid || appointment.updated_at == invoice.appointment_updated_at do
      {:ok, invoice}
    else
      update_invoice_from_appointment(invoice, appointment, params, school_context)
    end
  end

  defp update_invoice_from_appointment(invoice, appointment, params, school_context) do
    invoice_payload = get_invoice_payload(appointment, params, school_context)

    case CalculateInvoice.run(invoice_payload, school_context) do
      {:ok, invoice_params} ->
        invoice_params = update_invoice_params(invoice, invoice_params)
        UpdateInvoice.run(invoice, invoice_params, school_context)

      {:error, errors} ->
        {:error, errors}
    end
  end

  defp create_invoice_from_appointment(appointment, params, school_context) do
    invoice_payload = get_invoice_payload(appointment, params, school_context)
  
    case CalculateInvoice.run(invoice_payload, school_context) do
      {:ok, invoice_params} ->
        CreateInvoice.run(invoice_params, school_context)

      {:error, errors} ->
        {:error, errors}
    end
  end

  defp get_appointment(appointment_id) do
    Repo.get(Appointment, appointment_id)
    |> Repo.preload([:user, :instructor_user, :aircraft, :room, :simulator])
  end

  def get_invoice_payload(appointment, params, school_context) do
    school = school(school_context)
    current_user = school_context.assigns.current_user
    user_id = 
      cond do
        appointment.user_id not in [nil, "", " "] -> appointment.user_id
        !appointment.demo -> appointment.instructor_user_id
        true -> nil
      end

    # %{
    #   "school_id" => school.id,
    #   "appointment_id" => appointment.id,
    #   "user_id" => user_id,
    #   "payer_name" => payer_name_from(appointment),
    #   "demo" => appointment.demo,
    #   "date" => NaiveDateTime.to_date(appointment.end_at),
    #   "payment_option" => Map.get(params, "payment_option", "balance"),
    #   "line_items" => line_items_from(appointment, params, current_user),
    #   "appointment_updated_at" => appointment.updated_at
    # }
    
    # default value for payment options is added as balance.

    payload = 
      %{
        "school_id" => school.id,
        "appointment_id" => appointment.id,
        "user_id" => user_id,
        "payer_name" => payer_name_from(appointment),
        "demo" => appointment.demo,
        "date" => NaiveDateTime.to_date(appointment.end_at),
        "line_items" => line_items_from(appointment, params, current_user),
        "appointment_updated_at" => appointment.updated_at
      }

    payment_option = Map.get(params, "payment_option")

    cond do
      payment_option -> Map.put(payload, "payment_option", payment_option)
      # !appointment.demo -> Map.put(payload, "payment_option", Map.get(params, "payment_option", "balance"))
      true -> payload
    end
  end

  defp payer_name_from(appointment) do
    if appointment.demo, do: appointment.payer_name, else: Flight.Accounts.User.full_name(appointment.user || appointment.instructor_user)
  end

  defp line_items_from(appointment, params, current_user) do
    duration = Timex.diff(appointment.end_at, appointment.start_at, :minutes) / 60.0

    [
      aircraft_item(appointment, duration, params, current_user),
      simulator_item(appointment, duration, params, current_user),
      instructor_item(appointment, duration, current_user),
      room_item(appointment, 1, current_user)
    ]
    |> Enum.filter(fn x -> x end)
  end

  defp update_invoice_params(invoice, invoice_params) do
    custom_line_items =
      invoice.line_items
      |> Enum.filter(fn x -> !Enum.member?(@invoice_line_item_excluded_types, x.type) end)
      |> Enum.map(fn x -> Map.from_struct(x) |> Map.take(@invoice_line_item_fields) end)
      |> Enum.concat(invoice_params["line_items"])

    Map.put(invoice_params, "line_items", custom_line_items)
  end

  def aircraft_item(appointment, quantity, params \\ %{}, current_user) do
    if appointment.aircraft do
      rate = appointment.aircraft.rate_per_hour
      hobbs_end = Map.get(params, "hobbs_time", nil)
      tach_end = Map.get(params, "tach_time", nil)
      aircraft = appointment.aircraft

      %{
        "description" => "Flight Hours",
        "rate" => rate,
        "quantity" => quantity,
        "amount" => round(rate * quantity),
        "type" => :aircraft,
        "aircraft_id" => aircraft.id,
        "taxable" => true,
        "deductible" => false,
        "hobbs_tach_used" => !!(hobbs_end || tach_end),
        "hobbs_start" => aircraft.last_hobbs_time,
        "tach_start" => aircraft.last_tach_time,
        "hobbs_end" => hobbs_end,
        "tach_end" => tach_end,
        "creator_id" => current_user.id
      }
    end
  end

  def room_item(appointment, quantity, current_user) do
    if room = appointment.room do
      rate = room.rate_per_hour

      %{
        "description" => "Room",
        "rate" => rate,
        "quantity" => quantity,
        "amount" => round(rate * quantity),
        "type" => :room,
        "room_id" => room.id,
        "taxable" => false,
        "deductible" => false,
        "creator_id" => current_user.id
      }
    end
  end

  def instructor_item(appointment, quantity, current_user) do
    if instructor = appointment.instructor_user do
      rate = instructor.billing_rate

      %{
        "description" => "Instructor Hours",
        "rate" => rate,
        "quantity" => quantity,
        "amount" => round(rate * quantity),
        "type" => :instructor,
        "instructor_user_id" => instructor.id,
        "taxable" => false,
        "deductible" => false,
        "creator_id" => current_user.id
      }
    end
  end

  def simulator_item(appointment, quantity, params \\ %{}, current_user) do
    if appointment.simulator do
      rate = appointment.simulator.rate_per_hour
      hobbs_end = Map.get(params, "hobbs_time", nil)
      tach_end = Map.get(params, "tach_time", nil)
      simulator = appointment.simulator

      %{
        "description" => "Simulator Hours",
        "rate" => rate,
        "quantity" => quantity,
        "amount" => round(rate * quantity),
        "type" => :aircraft,
        "aircraft_id" => simulator.id,
        "taxable" => true,
        "deductible" => false,
        "hobbs_tach_used" => !!(hobbs_end || tach_end),
        "hobbs_start" => simulator.last_hobbs_time,
        "tach_start" => simulator.last_tach_time,
        "hobbs_end" => hobbs_end,
        "tach_end" => tach_end,
        "creator_id" => current_user.id
      }
    end
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end
end
