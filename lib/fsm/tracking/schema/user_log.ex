defmodule Fsm.Tracking.UserLog do
    use Ecto.Schema
    import Ecto.Changeset
    
    schema "user_logs" do
        field(:device_id, :string)
        field(:device_type, :string)
        field(:session_id, :string)
        field(:os_version, :string)
        field(:app_id, :string)
        field(:app_version, :string)
        belongs_to(:user, Fsm.Accounts.User)
        timestamps()
    end

    @doc false
    def changeset(log, attrs) do
      log
      |> cast(attrs, [
        :device_id,
        :device_type,
        :session_id,
        :os_version,
        :app_id,
        :app_version,
        :user_id
      ])
      |> validate_required([
        :device_id,
        :device_type,
        :session_id,
        :os_version,
        :app_id,
        :app_version,
        :user_id
      ])
    end

end