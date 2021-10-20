defmodule FsmWeb.GraphQL.Courses.CoursesResolvers do
    use FsmWeb.GraphQL.Errors
    alias FsmWeb.GraphQL.EctoHelpers
    alias Fsm.Accounts
    require Logger

    def get_courses(_parent,_args, %{context: %{current_user: current_user}}) do
        Logger.info fn -> "current_user111: #{inspect current_user}" end
            #user =  Accounts.get_user(current_user.id)
       isAdmin =  Enum.member?(current_user.roles, "admin")
        Logger.info fn -> "isAdmin222222222222: #{inspect isAdmin}" end
        courses = Flight.General.get_lms_courses(current_user, isAdmin)
        Logger.info fn -> "courses1111111111: #{inspect courses}" end
        {:ok, courses}
#        Logger.info fn -> "courses1111111111: #{inspect courses}" end
#        Logger.info fn -> "user222: #{inspect user}" end
#        squawk = Squawks.get_squawk(squawk_id)
#        {:ok, squawk}
    end

    def get_courses(_parent, _args, _context), do: @not_authenticated

    def get_course(_parent, %{id: course_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.get_course_detail(current_user, course_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def get_course(_parent, _args, _context), do: @not_authenticated

    def get_cumulative_results_lesson_level(_parent, %{course_id: course_id, lesson_id: lesson_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.get_cumulative_results_lesson_level(current_user, course_id, lesson_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def get_cumulative_results_lesson_level(_parent, _args, _context), do: @not_authenticated

    def cumulative_results_course_level(_parent, %{course_id: course_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.cumulative_results_course_level(current_user, course_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def cumulative_results_course_level(_parent, _args, _context), do: @not_authenticated

    def checklist_objective_remarks(_parent, %{course_id: course_id, course_module_id: course_module_id, item_id: item_id}, %{context: %{current_user: current_user}}) do
      course = Flight.General.checklist_objective_remarks(current_user, course_id, course_module_id, item_id)
      Logger.info fn -> "course: #{inspect course}" end
      {:ok, course}
    end

    def checklist_objective_remarks(_parent, _args, _context), do: @not_authenticated
end
