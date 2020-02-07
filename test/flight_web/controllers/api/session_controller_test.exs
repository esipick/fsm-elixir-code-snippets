defmodule FlightWeb.API.SessionControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "POST /api/login" do
    test "logs in successfully", %{conn: conn} do
      user =
        user_fixture(%{email: "food@bard.com", password: "oh hey there"})
        |> FlightWeb.API.UserView.show_preload()

      json =
        conn
        |> post("/api/login", %{email: "food@bard.com", password: "oh hey there"})
        |> json_response(200)

      assert {:ok, user_id, _token} =
               FlightWeb.AuthenticateApiUser.user_id_from_token(json["token"])

      assert user_id == user.id

      assert json ==
               render_json(
                 FlightWeb.API.SessionView,
                 "login.json",
                 user: user,
                 token: json["token"]
               )
    end

    test "401 if incorrect password", %{conn: conn} do
      _ = user_fixture(%{email: "food@bard.com", password: "oh hey there"})

      conn
      |> post("/api/login", %{email: "food@bard.com", password: "oh hey there sam"})
      |> json_response(401)
    end

    test "401 if incorrect email", %{conn: conn} do
      _ = user_fixture(%{email: "food@bard.commers", password: "oh hey there"})

      conn
      |> post("/api/login", %{email: "food@bard.com", password: "oh hey there"})
      |> json_response(401)
    end
  end
end
