defmodule FlightWeb.API.SessionViewTest do
  use FlightWeb.ConnCase, async: true

  import Phoenix.View

  test "login.json" do
    user =
      user_fixture()
      |> FlightWeb.API.UserView.show_preload()

    token = "some token"

    assert render(FlightWeb.API.SessionView, "login.json", user: user, token: token) == %{
             user: render(FlightWeb.API.UserView, "user.json", user: user),
             token: "some token"
           }
  end
end
