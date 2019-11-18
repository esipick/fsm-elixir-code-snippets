defmodule FlightWeb.API.InvoiceLineItemView do
  use FlightWeb, :view

  alias FlightWeb.API.{UserView, AircraftView}

  def render("line_item.json", %{line_item: line_item}) do
    line_item = Flight.Repo.preload(line_item, [:instructor_user, :aircraft])

    %{
      id: line_item.id,
      rate: line_item.rate,
      amount: line_item.amount,
      quantity: line_item.quantity,
      type: line_item.type,
      description: line_item.description,
      instructor_user_id: line_item.instructor_user_id,
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
end
