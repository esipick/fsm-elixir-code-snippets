defmodule FlightWeb.SessionViewTest do
  use FlightWeb.ConnCase, async: true

  import Phoenix.View

  test "login.json" do
    user = user_fixture()
    token = "some token"

    assert render(FlightWeb.SessionView, "login.json", user: user, token: token) == %{
             user: render(FlightWeb.UserView, "user.json", user: user),
             token: "some token"
           }
  end
end
