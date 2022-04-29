defmodule FlightWeb.Admin.ScheduleController do
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
    types = Flight.Scheduling.Appointment.types()
    instructor_times = Flight.Scheduling.Appointment.instructor_times()

    squawks = Fsm.Squawks.get_squawks(aircrafts)

    render(conn, "index.html",
      renters: renters,
      instructors: instructors,
      aircrafts: aircrafts,
      squawks: squawks,
      simulators: simulators,
      rooms: rooms,
      types: types,
      mechanics: mechanics,
      instructor_times: instructor_times
    )
  end

  def show(conn, _) do
    render(conn, "show.html")
  end
end
