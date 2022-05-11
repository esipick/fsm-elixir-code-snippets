defmodule FsmWeb.GraphQL.Alerts.AlertsResolvers do

  alias Flight.Alerts
  alias FsmWeb.GraphQL.Log


  def get_alert(parent, %{id: id}=args, %{context: %{current_user: %{school_id: school_id}=school_context}}=context) do
    alert = Alerts.get_alert(id, school_context)
    resp = {:ok, alert}
    Log.response(resp, __ENV__.function)
  end

  def list_alerts(parent, args, %{context: %{current_user: school_context}}=context) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :created_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    alerts = Alerts.list_alerts(page, per_page, sort_field, sort_order, filter, school_context)

    resp = {:ok, %{alerts: alerts, page: page}}
    Log.response(resp, __ENV__.function, :info)
  end
end
