defmodule FsmWeb.GraphQL.Tracking.UserLogsTypes do
  use Absinthe.Schema.Notation
  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Tracking.UserLogsResolvers

  object :user_logs_queries do
  end

  object :user_logs_mutations do
    @desc "create a new user log in database"
    field :create_user_log, non_null(:user_log) do
        arg :user_log, non_null(:create_user_log_input)
        middleware Middleware.Authorize
        resolve &UserLogsResolvers.create_user_log/3
    end
  end


  input_object :create_user_log_input do
    field(:device_id, :string)
    field(:device_type, :string)
    field(:session_id, :string)
    field(:os_version, :string)
    field(:app_id, :string)
    field(:app_version, :string)
  end

  object :user_log do
    field(:id, :integer)
    field(:device_id, :string)
    field(:device_type, :string)
    field(:session_id, :string)
    field(:os_version, :string)
    field(:app_id, :string)
    field(:app_version, :string)
    field(:user_id, :integer)
    field(:updated_at, :date)
  end

end