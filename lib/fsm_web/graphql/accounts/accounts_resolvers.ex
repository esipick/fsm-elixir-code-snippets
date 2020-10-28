defmodule FlightWeb.GraphQL.Accounts.AccountsResolvers do
  alias FlightWeb.API.SessionController
  require Logger
    def login(_parent, %{email: email, password: password} = params, resolution) do
      SessionController.api_login(resolution, %{"email" => email, "password"=> password} )
    end
  end
  