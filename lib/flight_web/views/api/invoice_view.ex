defmodule FlightWeb.API.InvoiceView do
  use FlightWeb, :view

  alias FlightWeb.API.{UserView, InvoiceView, AppointmentView, InvoiceLineItemView}

  def render("show.json", %{invoice: invoice}) do
    %{data: render("invoice.json", invoice: invoice)}
  end

  def render("invoice.json", %{invoice: invoice}) do
    line_items = invoice.line_items |> Enum.sort_by(fn x -> x.description end)

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
      line_items: render_many(line_items, InvoiceLineItemView, "line_item.json", as: :line_item)
    }
  end

  def render("index.json", %{invoices: invoices}) do
    %{data: render_many(invoices, InvoiceView, "invoice.json", as: :invoice)}
  end

  def render("appointments.json", %{appointments: appointments}) do
    %{data: render_many(appointments, AppointmentView, "appointment.json", as: :appointment)}
  end

  def render_appointment(appointment) do
    appointment = Flight.Repo.preload(appointment, [:user, :instructor_user, [aircraft: :inspections]])
    render(AppointmentView, "appointment.json", appointment: appointment)
  end
end
