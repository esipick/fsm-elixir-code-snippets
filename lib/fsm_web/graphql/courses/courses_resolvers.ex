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


end
