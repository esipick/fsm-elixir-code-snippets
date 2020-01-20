defmodule FlightWeb.Admin.SchoolController do
  use FlightWeb, :controller

  alias Flight.{Scheduling, Accounts}

  plug(:verify_superadmin)

  def index(conn, _) do
    list_items = FlightWeb.Admin.SchoolListItem.items_from_schools(Flight.Accounts.get_schools())
    render(conn, "index.html", school_list_items: list_items, hide_school_info: true)
  end

  def show(conn, %{"id" => id}) do
    school =
      Flight.Accounts.get_school(id)
      |> Flight.Repo.preload([:stripe_account])

    student_count = Accounts.get_user_count(Accounts.Role.student(), school)
    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), school)
    renter_count = Accounts.get_user_count(Accounts.Role.renter(), school)
    aircraft_count = Scheduling.visible_aircraft_count(school)

    render(
      conn,
      "show.html",
      school: school,
      student_count: student_count,
      instructor_count: instructor_count,
      renter_count: renter_count,
      aircraft_count: aircraft_count,
      hide_school_info: true
    )
  end

  def delete(conn, %{"id" => id}) do
    school = Flight.Accounts.get_school(id)

    Flight.Accounts.archive_school(school)

    redirect(conn, to: "/admin/schools")
  end

  defp verify_superadmin(conn, _) do
    if Flight.Accounts.is_superadmin?(conn.assigns.current_user) do
      conn
    else
      redirect(conn, to: "/admin/dashboard")
    end
  end
end
