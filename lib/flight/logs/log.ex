defmodule Flight.Log do
  alias Flight.Logs.AuditLog
  alias Flight.Accounts.User
  alias Flight.Accounts.School

  alias Flight.Repo
  alias Flight.SchoolScope
  import Ecto.Changeset
  import Ecto.Query, warn: false

  def record(:record_tach_time_change, %{
    tach_start: tach_start, 
    tach_end: tach_end,
    school_id: _school_id,
    user_id: _user_id,
    aircraft_id: _aircraft_id
    } = info) do
    info = 
      info
      |> Map.put(:action_description, "Updated Tach Hours from <b>#{tach_start}</b> to <b>#{tach_end}</b>.")
      |> Map.put(:action, "Changed Aircraft Tach Hours")
  
      insert_aircraft_audit_log(info)
      :ok
  end

  def record(:record_hobbs_time_change, %{
    hobbs_start: hobbs_start, 
    hobbs_end: hobbs_end,
    school_id: _school_id,
    user_id: _user_id,
    aircraft_id: _aircraft_id
    } = info) do
    info = 
      info
      |> Map.put(:action_description, "Updated Hobbs Hours from <b>#{hobbs_start}</b> to <b>#{hobbs_end}</b>.")
      |> Map.put(:action, "Changed Aircraft Hobbs Hours")
  
      insert_aircraft_audit_log(info)
      :ok

  end
  def record(_, _), do: :ok

  def insert_aircraft_audit_log(attrs) do
    %AuditLog{}
    # |> SchoolScope.school_changeset(school_context)
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

#  |> join(:inner, [a], u in assoc(a, :users))
  def visible_aircraft_logs_query(school_context, search_term \\ "") do
    aircraft_id = school_context.assigns.aircraft.id
    aircraft_logs_query(school_context, search_term)
    |> join(:inner, [a], u in User, on: a.user_id == u.id)
    |> join(:inner, [l], s in School, on: l.school_id == s.id)
    |> select([l, u, s], %{
        id: l.id, 
        school_id: l.school_id, 
        user_id: l.user_id, 
        action_description: l.action_description, 
        updated_at: l.updated_at, 
        school_name: s.name, 
        user_name: fragment("concat(?, ' ', ?)", u.first_name, u.last_name),
        aircraft_id: l.aircraft_id})
    |> where([a], a.archived == false)
    |> where([a], a.aircraft_id == ^aircraft_id  )
    |> order_by([a], desc: [a.updated_at])
  end

  def aircraft_logs_query(school_context, search_term \\ "") do
    AuditLog
    |> Flight.Scheduling.Search.AircraftLogs.run(search_term)
    # |> SchoolScope.scope_query(school_context)
  end

  def visible_aircraft_logs_count(school_context) do
    visible_aircraft_logs_query(school_context)
    |> Repo.aggregate(:count, :id)
  end

  def archive_log(%AuditLog{} = audit_log) do
    audit_log
    |> AuditLog.archive_changeset(%{archived: true})
    |> Repo.update()
  end
end
