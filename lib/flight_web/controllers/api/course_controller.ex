defmodule FlightWeb.API.CourseController do
  use FlightWeb, :controller
  alias Flight.Curriculum
  alias Flight.General, as: Course

  def index(conn, _) do
    courses = Curriculum.get_courses()
    render(conn, "index.json", courses: courses)
  end

  def sublesson_remarks(conn, attrs) do
    %{assigns: %{current_user: user}} = conn

    attrs = %{
      course_id: Map.get(attrs, "course_id"),
      sub_lesson_id: Map.get(attrs, "sub_lesson_id"),
      teacher_mark: Map.get(attrs, "teacher_mark"),
      fsm_user_id: Map.get(attrs, "fsm_user_id"),
      note: Map.get(attrs, "notes")
    }
    
    participant_course_info = Course.insert_lesson_sub_lesson_remarks(user, attrs)
    
    render(conn, "participant_course_info.json", participant_course_info: participant_course_info)
  end

  def sublesson_module_view(conn, attrs) do
    %{assigns: %{current_user: user}} = conn

    attrs = %{
      course_id: Map.get(attrs, "course_id"),
      course_module_id: Map.get(attrs, "module_id")
    }

    response = Course.add_course_module_view_remarks(user,attrs)
    render(conn, "course_module_view.json", module_view_response: response)
  end

end
