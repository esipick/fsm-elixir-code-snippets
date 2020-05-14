defmodule FlightWeb.API.InvoiceLineItemView do
  use FlightWeb, :view

  alias FlightWeb.API.{UserView, AircraftView}

  def render("line_item.json", %{line_item: line_item}) do
    line_item = Flight.Repo.preload(line_item, [:instructor_user, :aircraft])

    %{
      id: line_item.id,
      description: line_item.description,
      rate: line_item.rate,
      amount: line_item.amount,
      quantity: line_item.quantity,
      type: line_item.type,
      instructor_user_id: line_item.instructor_user_id,
      hobbs_start: line_item.hobbs_start,
      hobbs_end: line_item.hobbs_end,
      tach_start: line_item.tach_start,
      tach_end: line_item.tach_end,
      hobbs_tach_used: line_item.hobbs_tach_used,
      aircraft_id: line_item.aircraft_id,
      taxable: line_item.taxable,
      deductible: line_item.deductible,
      aircraft:
        Optional.map(
          line_item.aircraft,
          &render(AircraftView, "skinny_aircraft.json", aircraft: &1)
        ),
      instructor_user:
        Optional.map(
          line_item.instructor_user,
          &render(UserView, "skinny_user.json", user: &1)
        )
    }
  end
end
