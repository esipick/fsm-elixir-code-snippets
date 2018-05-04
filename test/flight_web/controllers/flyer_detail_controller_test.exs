defmodule FlightWeb.FlyerDetailControllerTest do
  use FlightWeb.ConnCase, async: true

  # describe "GET /api/users/:id/flyer_details" do
  #   test "renders", %{conn: conn} do
  #     user =
  #       user_fixture()
  #       |> assign_role("student")
  #
  #     json =
  #       conn
  #       |> auth(user)
  #       |> get("/api/users/#{user.id}/flyer_details")
  #       |> json_response(200)
  #
  #     flyer_details = Flight.Accounts.get_flyer_details_for_user_id(user.id)
  #
  #     assert json ==
  #              render_json(FlightWeb.FlyerDetailView, "show.json", flyer_details: flyer_details)
  #   end
  # end
  #
  # describe "PUT /api/users/:id/flyer_details" do
  #   test "updates", %{conn: conn} do
  #     user = user_fixture()
  #     # |> assign_role("student")
  #
  #     flyer_details_fixture(%{}, user)
  #
  #     flyer_details = %{
  #       Flight.Accounts.get_flyer_details_for_user_id(user.id)
  #       | address_1: "from_api"
  #     }
  #
  #     json =
  #       conn
  #       |> auth(user)
  #       |> put("/api/users/#{user.id}/flyer_details", %{data: %{address_1: "from api"}})
  #       |> json_response(200)
  #
  #     assert render_json(FlightWeb.FlyerDetailView, "show.json", flyer_details: flyer_details)
  #   end
  #
  #   test "permissions", %{conn: conn} do
  #   end
  # end
end
