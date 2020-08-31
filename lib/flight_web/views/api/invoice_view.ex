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
      user:
        Optional.map(
          invoice.user,
          &render(UserView, "skinny_user.json", user: &1)
        ),
      payer_name: invoice.payer_name,
      user_id: invoice.user_id,
      payment_option: invoice.payment_option,
      date: invoice.date,
      total: invoice.total,
      tax_rate: invoice.tax_rate,
      total_tax: invoice.total_tax,
      total_amount_due: invoice.total_amount_due,
      status: invoice.status,
      appointment_id: invoice.appointment_id,
      aircraft_info: invoice.aircraft_info,
      appointment:
        Optional.map(
          invoice.appointment,
          &render_appointment(&1)
        ),
      line_items: render_many(line_items, InvoiceLineItemView, "line_item.json", as: :line_item),
      connect_account: Map.get(invoice, :connect_account),
      session_id: Map.get(invoice, :session_id),
      pub_key: Map.get(invoice, :pub_key)
    }
  end

  def render("delete.json", %{invoice: invoice}) do
    %{id: invoice.id}
  end

  def render("index.json", %{invoices: invoices}) do
    %{data: render_many(invoices, InvoiceView, "invoice.json", as: :invoice)}
  end

  def render("appointments.json", %{appointments: appointments}) do
    %{data: render_many(appointments, AppointmentView, "appointment.json", as: :appointment)}
  end

  def render("payment_options.json", _) do
    %{
      data:
        Enum.map(InvoicePaymentOptionEnum.__enum_map__(), fn x ->
          {key, value} = x
          [Atom.to_string(key), value]
        end)
    }
  end

  def render_appointment(appointment) do
    appointment =
      Flight.Repo.preload(appointment, [
        :user,
        :school,
        :instructor_user,
        :room,
        [aircraft: :inspections],
        [simulator: :inspections]
      ])

    render(AppointmentView, "appointment.json", appointment: appointment)
  end
end
