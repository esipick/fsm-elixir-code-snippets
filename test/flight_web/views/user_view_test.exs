defmodule FlightWeb.UserViewTest do
  use FlightWeb.ConnCase, async: true

  import Phoenix.View

  test "show.json" do
    user = user_fixture(%{})

    assert render(FlightWeb.UserView, "show.json", user: user) == %{
             data: render(FlightWeb.UserView, "user.json", user: user)
           }
  end

  test "user.json" do
    user =
      user_fixture(%{
        first_name: "Tim",
        last_name: "Johnson",
        email: "foo@bar.com"
      })

    assert render(FlightWeb.UserView, "user.json", user: user) == %{
             id: user.id,
             first_name: "Tim",
             last_name: "Johnson",
             email: "foo@bar.com",
             balance: 0
           }
  end
end
