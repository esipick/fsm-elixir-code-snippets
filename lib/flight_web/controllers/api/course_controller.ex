defmodule FlightWeb.API.CourseController do
  use FlightWeb, :controller

  alias Flight.Curriculum

  def index(conn, _) do
    courses = Curriculum.get_courses()
    render(conn, "index.json", courses: courses)
  end
end
