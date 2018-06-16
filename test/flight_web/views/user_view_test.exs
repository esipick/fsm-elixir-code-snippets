defmodule FlightWeb.API.UserViewTest do
  use FlightWeb.ConnCase, async: true

  import Phoenix.View
  alias FlightWeb.API.UserView

  test "show.json" do
    user =
      user_fixture()
      |> Flight.Repo.preload([:roles, :flyer_certificates])

    assert render(UserView, "show.json", user: user) == %{
             data: render(UserView, "user.json", user: user)
           }
  end

  # test "user.json" do
  #   user =
  #     user_fixture(%{
  #       first_name: "Tim",
  #       last_name: "Johnson",
  #       email: "foo@bar.com"
  #     })
  #
  #   assert render(UserView, "user.json", user: user) == %{
  #            id: user.id,
  #            first_name: "Tim",
  #            last_name: "Johnson",
  #            email: "foo@bar.com",
  #            balance: 0
  #          }
  # end
end
