defmodule FlightWeb.Features.CreateSimulatorTest do
  use FlightWeb.FeatureCase, async: true

  @tag :integration
  test "admin can create simulator", %{session: session} do
    session
    |> log_in_admin()
    |> visit("/admin/simulators/new")
    |> assert_has(css(".card-title", text: "New simulator"))
    |> fill_in(text_field("data_make"), with: "falcon")
    |> fill_in(text_field("data_model"), with: "x-wing")
    |> fill_in(text_field("data_name"), with: "Falcon Simulator")
    |> fill_in(text_field("data_serial_number"), with: "65-46465")
    |> fill_in(text_field("data_rate_per_hour"), with: "15")
    |> fill_in(text_field("data_block_rate_per_hour"), with: "9")
    |> fill_in(text_field("data_equipment"), with: "headphones")
    |> click(button("Save"))
    |> assert_has(css(".title", text: "Falcon Simulator"))
  end
end
