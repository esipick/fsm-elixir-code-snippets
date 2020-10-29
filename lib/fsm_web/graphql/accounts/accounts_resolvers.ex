defmodule FlightWeb.GraphQL.Accounts.AccountsResolvers do
  alias FSM.Accounts
  require Logger
    def login(_parent, %{email: email, password: password} = params, resolution) do
      Accounts.api_login(%{"email" => email, "password"=> password} )
    end
  end
  