defmodule FlightWeb.API.SchoolController do
  use FlightWeb, :controller

  alias Flight.Auth.Permission

  plug(:get_school when action in [:index])
  plug(:authorize_view when action in [:index])

  def index(conn, _) do
    school = Flight.SchoolScope.get_school(conn)

    render(conn, "index.json", school: school)
  end

  def authorize_view(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:school, :view, {:personal, conn.assigns.school})
    ])
  end

  defp get_school(conn, _) do
    assign(conn, :school, Flight.SchoolScope.get_school(conn))
  end
end
