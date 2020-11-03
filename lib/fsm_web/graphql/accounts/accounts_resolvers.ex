defmodule FsmWeb.GraphQL.Accounts.AccountsResolvers do

  alias Fsm.Accounts
  alias FsmWeb.GraphQL.Accounts.UserView
  require Logger

  def login(_parent, %{email: email, password: password} = params, resolution) do
    Accounts.api_login(%{"email" => email, "password"=> password} )
  end

  def get_current_user(parent, _args, %{context: %{current_user: %{id: id}}}=context) do
    user =
      Accounts.get_user(id)
      |> UserView.map

    {:ok, user}
  end

  def get_user(parent, args, %{context: %{current_user: %{id: id}}}=context) do
    user =
      Accounts.get_user(args.id)
      |> UserView.map

    {:ok, user}
  end

  def list_users(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    users = Accounts.list_users(page, per_page, sort_field, sort_order, filter, context)
            |> UserView.map
    {:ok, users}
  end
end
  