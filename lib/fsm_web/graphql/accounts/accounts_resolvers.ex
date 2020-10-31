
defmodule FsmWeb.GraphQL.Accounts.AccountsResolvers do
  alias Fsm.Accounts

  require Logger
    def login(_parent, %{email: email, password: password} = params, resolution) do
      Logger.info fn -> "resolution: #{}" end
      Accounts.api_login(%{"email" => email, "password"=> password} )
    end

    def all_users(parent, _params, resolution) do
      Logger.info fn -> "resolution: #{inspect resolution}" end
      Logger.info fn -> "parent: #{inspect parent}" end
      {:ok, []}
    end
  end
  