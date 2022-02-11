defmodule FlightWeb.Mechanic.ScheduleController do
  use FlightWeb, :controller

  alias Flight.Accounts.Role

  def index(conn, _) do
    current_user = conn.assigns.current_user
    renters = Flight.Accounts.users_with_roles([Role.student(), Role.renter()], conn)
    instructors = Flight.Accounts.users_with_roles([Role.instructor()], conn)
    mechanics = Flight.Accounts.users_with_roles([Role.mechanic()], conn)
    aircrafts = Flight.Scheduling.visible_aircrafts(conn)
    simulators = Flight.Scheduling.visible_simulators(conn)
    rooms = Flight.SchoolAssets.visible_rooms(conn)

    # We could do that types = ["maintenance"]
    # however we're keeping a single
    # source for appointment types
    types = Flight.Scheduling.Appointment.types()
      |> Enum.filter(fn x -> x == "maintenance" end)

    render(conn, "index.html",
      renters: renters,
      instructors: instructors,
      aircrafts: aircrafts,
      mechanics: mechanics,
      user_id: current_user.id,
      simulators: simulators,
      rooms: rooms,
      types: types
    )
  end

  def show(conn, _) do
    render(conn, "show.html")
  end
end
