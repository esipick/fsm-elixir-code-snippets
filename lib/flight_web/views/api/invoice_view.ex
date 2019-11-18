defmodule FlightWeb.API.InvoiceView do
  use FlightWeb, :view

  alias FlightWeb.API.{UserView, InvoiceView, AircraftView, AppointmentView}

  def render("show.json", %{invoice: invoice}) do
    %{data: render("invoice.json", invoice: invoice)}
  end

  def render("invoice.json", %{invoice: invoice}) do
    %{
      id: invoice.id,
      user: render(UserView, "skinny_user.json", user: invoice.user),
      user_id: invoice.user_id,
      payment_option: invoice.payment_option,
      date: invoice.date,
      total: invoice.total,
      tax_rate: invoice.tax_rate,
      total_tax: invoice.total_tax,
      total_amount_due: invoice.total_amount_due,
      appointment: Optional.map(
        invoice.appointment,
        &render_appointment(&1)
      ),
      line_items: render_many(invoice.line_items, InvoiceView, "line_item.json", as: :line_item)
    }
  end

  def render_appointment(appointment) do
    appointment = Flight.Repo.preload(appointment, [:user, :instructor_user, [aircraft: :inspections]])
    render(AppointmentView, "appointment.json", appointment: appointment)
  end

  def render("line_item.json", %{line_item: line_item}) do
    line_item = Flight.Repo.preload(line_item, [:instructor_user, :aircraft])

    %{
      description: line_item.description,
      rate: line_item.rate,
      amount: line_item.amount,
      quantity: line_item.quantity,
      type: line_item.type,
      aircraft_id: line_item.aircraft_id,
      aircraft: Optional.map(
        line_item.aircraft,
        &render(AircraftView, "skinny_aircraft.json", aircraft: &1)
      ),
      instructor_user: Optional.map(
        line_item.instructor_user,
        &render(UserView, "skinny_user.json", user: &1)
      )
    }
  end

  def render("index.json", %{invoices: invoices}) do
    %{data: render_many(invoices, InvoiceView, "invoice.json", as: :invoice)}
  end

  def render("appointments.json", %{appointments: appointments}) do
    %{data: render_many(appointments, AppointmentView, "appointment.json", as: :appointment)}
  end
end
