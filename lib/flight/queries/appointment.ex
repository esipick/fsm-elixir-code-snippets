defmodule Flight.Queries.Appointment do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Flight.Scheduling.Appointment
  alias Flight.Billing.Invoice

  import Pipe

  alias Flight.SchoolScope

  def billable(school_context, params = %{}) do
    excluded_appointment_ids =
      from(
        i in Invoice,
        where:
          i.archived == false and not is_nil(i.appointment_id) and
            i.school_id == ^SchoolScope.school_id(school_context) and i.is_visible == true,
        select: i.appointment_id
      )
      |> Repo.all()

    from(a in Appointment, order_by: [desc: a.end_at])
    |> where([a], a.archived == false)
    |> where([a], a.status == "pending")
    |> where([a], a.id not in ^excluded_appointment_ids)
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(params["user_id"], &where(&1, [a], a.user_id == ^params["user_id"]))
    |> Repo.all()
  end

  def get_paid_appointments(school_context, params = %{}) do

    user_id = Map.get(params, "user_id")

    from(a in Appointment, order_by: [desc: a.end_at])
      |> where([a], a.archived == false)
      |> where([a], a.status == "paid")
      |> pass_unless(user_id, &where(&1, [a], a.user_id == ^user_id))
      |> Repo.all()
  end

end
