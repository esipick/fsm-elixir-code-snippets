defmodule FlightWeb.Mechanic.ScheduleController do
  use FlightWeb, :controller

  alias Flight.Accounts.Role

  def index(conn, _) do
    current_user = conn.assigns.current_user
    mechanics = Flight.Accounts.users_with_roles([Role.mechanic()], conn)
    aircrafts = Flight.Scheduling.visible_aircrafts(conn)

    # We could do that types = ["maintenance"]
    # however we're keeping a single
    # source for appointment types
    types = Flight.Scheduling.Appointment.types()
      |> Enum.filter(fn x -> x == "maintenance" end)
    instructor_times = Flight.Scheduling.Appointment.instructor_times()
    squawks = Fsm.Squawks.get_squawks(aircrafts)
    render(conn, "index.html",
      renters: [],
      instructors: [],
      aircrafts: aircrafts,
      squawks: squawks,
      mechanics: mechanics,
      instructor_times: instructor_times,
      mechanic_user_id: current_user.id,
      simulators: [],
      rooms: [],
      types: types
    )
  end

  def show(conn, _) do
    render(conn, "show.html")
  end
end
