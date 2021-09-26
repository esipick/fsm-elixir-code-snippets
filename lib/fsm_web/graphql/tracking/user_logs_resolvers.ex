defmodule FsmWeb.GraphQL.Tracking.UserLogsResolvers do
    alias Fsm.Tracking.UserLogs

    def create_user_log(parent, args, %{context: %{current_user: %{id: user_id}}}=context) do
        user_log = (Map.get(args, :user_log) || %{}) |> Map.put(:user_id, user_id)
        UserLogs.store(user_log)
    end
end