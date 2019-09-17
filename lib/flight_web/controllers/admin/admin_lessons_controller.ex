defmodule FlightWeb.Admin.LessonsController do
  use FlightWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def edit(conn, _) do
    render(conn, "edit.html")
  end

  def show(conn, %{"id" => id}) do
    lesson =
      Flight.Curriculum.get_lesson(id)
      |> IO.inspect()

    conn
    |> render("show.html", lesson: lesson)
  end
end
