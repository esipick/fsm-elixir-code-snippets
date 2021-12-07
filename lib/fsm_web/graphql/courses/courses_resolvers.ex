defmodule FsmWeb.GraphQL.Courses.CoursesResolvers do
    use FsmWeb.GraphQL.Errors
    alias FsmWeb.GraphQL.EctoHelpers
    alias Fsm.Accounts
    require Logger

    def get_courses(_parent,_args, %{context: %{current_user: current_user}}) do
        Logger.info fn -> "current_user111: #{inspect current_user}" end
      
        isAdmin =  Enum.member?(current_user.roles, "admin")
        Logger.info fn -> "isAdmin: #{inspect isAdmin}" end
        courses = Flight.General.get_lms_courses(current_user, isAdmin)
        Logger.info fn -> "courses: #{inspect courses}" end
        {:ok, courses}
    end

    def get_courses(_parent, _args, _context), do: @not_authenticated

    def get_course(_parent, %{id: course_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.get_course_detail(current_user, course_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def get_course(_parent, _args, _context), do: @not_authenticated

    def get_course_participants(_parent, %{course_id: course_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.get_course_participants(current_user, course_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def get_course_participants(_parent, _args, _context), do: @not_authenticated

    def get_course_lesson(_parent, %{course_id: course_id, lms_user_id: lms_user_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.get_course_lesson(current_user, course_id, lms_user_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def get_course_lesson(_parent, _args, _context), do: @not_authenticated

    def get_participant_course_lessons(_parent, %{course_id: course_id, lms_user_id: lms_user_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.get_participant_course_lessons(current_user, course_id, lms_user_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def get_participant_course_lessons(_parent, _args, _context), do: @not_authenticated

    def get_participant_course_sub_lessons(_parent, %{course_id: course_id, lms_user_id: lms_user_id, section_id: section_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.get_participant_course_sub_lessons(current_user, course_id, lms_user_id, section_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def get_participant_course_sub_lessons(_parent, _args, _context), do: @not_authenticated

    def get_participant_course_sub_lesson_modules(_parent, %{course_id: course_id, lms_user_id: lms_user_id, sub_lesson_id: sub_lesson_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.get_participant_course_sub_lesson_modules(current_user, course_id, lms_user_id, sub_lesson_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def get_participant_course_sub_lesson_modules(_parent, _args, _context), do: @not_authenticated

    def insert_lesson_sub_lesson_remarks(_parent, %{remark_input: attrs}, %{context: %{current_user: current_user}}) do
      course = Flight.General.insert_lesson_sub_lesson_remarks(current_user,attrs)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def insert_lesson_sub_lesson_remarks(_parent, _args, _context), do: @not_authenticated

    def add_course_module_view(_parent, %{input_course_module_view: attrs}, %{context: %{current_user: current_user}}) do
      response = Flight.General.add_course_module_view_remarks(current_user,attrs)
      Logger.info fn -> "response: #{inspect response}" end
      {:ok, response}
    end

    def add_course_module_view(_parent, _args, _context), do: @not_authenticated
end
