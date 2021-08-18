defmodule Fsm.Dashboard do
  alias Fsm.{Accounts, Scheduling}
  import Ecto.Query, warn: false

  @doc """
  returns user roles count stats
  """
  def list_roles_counts(context) do
    student_count = Accounts.get_user_count(Accounts.Role.student(), context)
    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), context)
    renter_count = Accounts.get_user_count(Accounts.Role.renter(), context)
    aircrafts = Scheduling.visible_air_assets(context)

    [
      %{
        title: "STUDENTS",
        count: student_count
      },
      %{
        title: "INSTRUCTORS",
        count: instructor_count
      },
      %{
        title: "RENTERS",
        count: renter_count
      },
      %{
        title: "AIRCRAFTS",
        count: Enum.count(aircrafts)
      }
    ]
  end
end
