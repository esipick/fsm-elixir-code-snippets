defmodule FlightWeb.API.CourseController do
  use FlightWeb, :controller

  alias Flight.Curriculum

  def index(conn, _) do
    courses = Curriculum.get_courses()

    courses =
      courses
      |> Flight.Repo.preload([
        :course_downloads,
        lessons: [lesson_categories: [:objectives]]
      ])

    render(conn, "index.json", courses: courses)
  end
end
