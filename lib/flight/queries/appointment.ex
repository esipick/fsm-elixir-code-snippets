defmodule Flight.Queries.Appointment do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Flight.Scheduling.Appointment

  import Pipe

  alias Flight.SchoolScope

  def billable(school_context, params = %{}) do
    datetime = DateTime.utc_now()

    from(i in Appointment, where: i.end_at <= ^datetime, order_by: [desc: i.end_at])
    |> where([i], i.archived == false)
    |> where([i], i.status == "pending")
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(params["user_id"], &where(&1, [t], t.user_id == ^params["user_id"]))
    |> Repo.all()
  end
end
