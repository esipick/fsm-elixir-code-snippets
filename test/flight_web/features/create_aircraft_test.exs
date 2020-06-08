defmodule FlightWeb.Features.CreateAircraftTest do
  use FlightWeb.FeatureCase, async: false

  @tag :skip
  test "admin can create aircraft", %{session: session} do
    session
    |> log_in_admin()
    |> visit("/admin/aircrafts/new")
    |> assert_has(css(".card-title", text: "New Aircraft"))
    |> fill_in(text_field("data_make"), with: "falcon")
    |> fill_in(text_field("data_model"), with: "x-wing")
    |> fill_in(text_field("data_tail_number"), with: "N69584")
    |> fill_in(text_field("data_serial_number"), with: "65-46465")
    |> fill_in(text_field("data_rate_per_hour"), with: "15")
    |> fill_in(text_field("data_block_rate_per_hour"), with: "9")
    |> fill_in(text_field("data_equipment"), with: "belt of egg")
    |> click(button("Save"))
    |> assert_has(css(".title", text: "falcon x-wing"))
  end
end
