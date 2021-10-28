defmodule FlightWeb.API.CourseController do
  use FlightWeb, :controller

  alias Flight.Curriculum

  def index(conn, _) do
    courses = Curriculum.get_courses()
    render(conn, "index.json", courses: courses)
  end

  def sublesson_remarks(conn, attrs) do
    %{assigns: %{current_user: user}} = conn
    
    response = Flight.Course.insert_lesson_sub_lesson_remarks(user, attrs)
    render(conn, "index.json", response)
  end

end
