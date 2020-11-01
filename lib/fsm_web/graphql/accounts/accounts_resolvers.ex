defmodule FsmWeb.GraphQL.Accounts.AccountsResolvers do
  alias Fsm.Accounts

  require Logger

  def login(_parent, %{email: email, password: password} = params, resolution) do
    Accounts.api_login(%{"email" => email, "password"=> password} )
  end

  def get_user(parent, _args, %{context: %{current_user: %{id: id}}}=context) do
    user = Accounts.get_user(id)
    {:ok, user}
  end

  def list_users(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    users = Accounts.list_users(page, per_page, sort_field, sort_order, filter, context)
    {:ok, users}
  end
end
  