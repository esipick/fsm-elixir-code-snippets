defmodule Flight.Logs.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field(:action, :string)
    field(:action_description, :string)
    field(:role, :string)
    field(:comment, :string)
    field(:archived, :boolean, default: false)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)
    belongs_to(:school, Flight.Accounts.School)
    belongs_to(:user, Flight.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(audit_logs, attrs) do
    audit_logs
    |> cast(attrs, [
      :action,
      :action_description,
      :role,
      :comment,
      :school_id,
      :aircraft_id,
      :user_id
    ])
    |> validate_required([
      :school_id,
      :user_id
    ])
  end

  def admin_changeset(audit_log, attrs) do
    changeset(audit_log, attrs)
  end

  def archive_changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:archived])
  end

  def archive(%Flight.Logs.AuditLog{} = audit_log) do
    audit_log
    |> change(archived: true)
    |> Flight.Repo.update()
  end
end
