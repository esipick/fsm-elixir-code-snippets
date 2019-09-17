defmodule FlightWeb.Admin.CoursesController do
  use FlightWeb, :controller

  def index(conn, _params) do
    conn
    |> render("index.html", courses: Flight.Curriculum.get_courses())
  end

  def show(conn, %{"id" => id}) do
    course =
      Flight.Curriculum.get_course(id)
      |> IO.inspect()

    conn
    |> render("show.html", course: course)
  end

  def edit(conn, _) do
    render(conn, "edit.html")
  end
end
