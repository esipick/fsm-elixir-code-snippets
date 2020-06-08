defmodule FlightWeb.Features.CreateRoomTest do
  use FlightWeb.FeatureCase, async: true

  @tag :integration
  test "admin can create room", %{session: session} do
    session
    |> log_in_admin()
    |> visit("/admin/rooms/new")
    |> assert_has(css(".card-title", text: "New room"))
    |> fill_in(text_field("data_location"), with: "7 Park Avenue")
    |> fill_in(text_field("data_rate_per_hour"), with: "15")
    |> fill_in(text_field("data_block_rate_per_hour"), with: "9")
    |> fill_in(text_field("data_resources"), with: "whiteboard")
    |> click(button("Save"))
    |> assert_has(css(".title", text: "7 Park Avenue"))
  end
end
