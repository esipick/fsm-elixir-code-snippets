defmodule FlightWeb.SessionView do
  use FlightWeb, :view

  def render("login.json", %{user: user, token: token}) do
    %{
      user: render(FlightWeb.UserView, "user.json", user: user),
      token: token
    }
  end
end
