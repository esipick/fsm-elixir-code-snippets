defmodule FsmWeb.GraphQL.Dashboard.DashboardResolvers do

  alias Fsm.Dashboard
#  alias FsmWeb.GraphQL.Scheduling.SchedulingView
  alias FsmWeb.GraphQL.Log

  def list_roles_counts(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    response = Dashboard.list_roles_counts(context)

    resp = {:ok, response}
    Log.response(resp, __ENV__.function, :info)
  end
end
  