defmodule FsmWeb.GraphQL.Accounts.AccountsResolvers do

  alias Fsm.Accounts
  alias FsmWeb.GraphQL.Accounts.UserView
  alias FsmWeb.GraphQL.Log

  def login(_parent, %{email: email, password: password} = params, resolution) do
    resp = Accounts.api_login(%{"email" => email, "password"=> password} )

    Log.response(resp, __ENV__.function, :info)
  end

  def get_current_user(parent, _args, %{context: %{current_user: %{id: id}}}=context) do
    user =
      Accounts.get_user(id)
      |> UserView.map

    resp = {:ok, user}
    Log.response(resp, __ENV__.function)
  end

  def get_user(parent, args, %{context: %{current_user: %{id: id}}}=context) do
    user =
      Accounts.get_user(args.id)
      |> UserView.map

    resp = {:ok, user}
    Log.response(resp, __ENV__.function)
  end

  def list_aircrafts(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    users =
      Aircrafts.list_aircrafts(page, per_page, sort_field, sort_order, filter, context)

    resp = {:ok, users}
    Log.response(resp, __ENV__.function, :info)
  end
end
  