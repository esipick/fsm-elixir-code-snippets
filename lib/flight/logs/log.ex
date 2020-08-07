defmodule Flight.Log do
  alias Flight.Scheduling.Aircraft
  alias Flight.Logs.AuditLog
  alias Flight.Accounts.User

  alias Flight.Repo
  alias Flight.SchoolScope
  import Ecto.Changeset
  import Ecto.Query, warn: false

  def insert_aircraft_audit_log(attrs, school_context) do
    %AuditLog{}
    |> SchoolScope.school_changeset(school_context)
    |> AuditLog.admin_changeset(attrs)
    |> Repo.insert()
  end

#  |> join(:inner, [a], u in assoc(a, :users))
  def visible_aircraft_logs_query(school_context, search_term \\ "") do
    aircraft_id = school_context.assigns.aircraft.id
    aircraft_logs_query(school_context, search_term)
    |> join(:inner, [a], u in User, on: a.user_id == u.id)
    |> where([a], a.archived == false)
    |> where([a], a.aircraft_id == ^aircraft_id  )
    |> order_by([a], desc: [a.updated_at])
  end

  def aircraft_logs_query(school_context, search_term \\ "") do
    AuditLog
    |> Flight.Scheduling.Search.AircraftLogs.run(search_term)
    |> SchoolScope.scope_query(school_context)
  end

  def visible_aircraft_logs_count(school_context) do
    visible_aircraft_logs_query(school_context)
    |> Repo.aggregate(:count, :id)
  end

  def archive_log(%AuditLog{} = audit_log) do
    audit_log
    |> Aircraft.archive_changeset(%{archived: true})
    |> Repo.update()
  end
end
