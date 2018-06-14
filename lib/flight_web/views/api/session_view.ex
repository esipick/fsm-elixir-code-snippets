defmodule FlightWeb.API.SessionView do
  use FlightWeb, :view

  def render("login.json", %{user: user, token: token}) do
    %{
      user: render(FlightWeb.API.UserView, "user.json", user: user),
      token: token
    }
  end
end
