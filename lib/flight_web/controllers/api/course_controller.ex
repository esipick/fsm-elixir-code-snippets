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

    teacher_mark = Map.get(attrs, "teacher_mark", nil)
    notes = Map.get(attrs, "notes", nil)

    new_attrs = %{
      course_id: Map.get(attrs, "course_id"),
      sub_lesson_id: Map.get(attrs, "sub_lesson_id"),
      fsm_user_id: Map.get(attrs, "fsm_user_id")
    }

    new_attrs = if is_nil(teacher_mark), do: new_attrs, else: Map.put(new_attrs, :teacher_mark, teacher_mark)
    
    new_attrs = if is_nil(notes), do: new_attrs, else: Map.put(new_attrs, :note, notes)
    
    response = Course.insert_lesson_sub_lesson_remarks_v2(user, new_attrs)
    
    render(conn, "sub_lesson_remarks.json", response: response)
  end

  def sublesson_module_view(conn, attrs) do
    %{assigns: %{current_user: user}} = conn

    attrs = %{
      course_id: Map.get(attrs, "course_id"),
      course_module_id: Map.get(attrs, "module_id"),
      action: Map.get(attrs, "action")
    }

    response = Course.add_course_module_view_remarks(user,attrs)
    render(conn, "course_module_view.json", module_view_response: response)
  end

  def get_sub_lessons(%{assigns: %{current_user: user}} = conn, attrs) do
      course_id = Map.get(attrs, "course_id")
      lms_user_id = Map.get(attrs, "lms_user_id")
      section_id = Map.get(attrs, "section_id")

      response = Course.get_participant_course_sub_lessons(user, course_id, lms_user_id, section_id)
      render(conn, "sub_lessons.json", sub_lessons: response)
  end


  def get_sub_lesson_modules(%{assigns: %{current_user: user}} = conn, attrs) do
    course_id = Map.get(attrs, "course_id")
    lms_user_id = Map.get(attrs, "lms_user_id")
    sub_lesson_id = Map.get(attrs, "sub_lesson_id")

    response = Course.get_participant_course_sub_lesson_modules(user, course_id, lms_user_id, sub_lesson_id)
    render(conn, "sub_lesson_modules.json", sub_lesson_modules: response)
  end

end
