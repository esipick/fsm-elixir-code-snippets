defmodule FlightWeb.GraphQL.Router do
    use FlightWeb, :router
    use Plug.ErrorHandler
    require Logger

    pipeline :api do
      plug :accepts, ["json"]
      plug FlightWeb.Context
    end
  
    scope "/api" do
      pipe_through :api

      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: FsmWeb.GraphQL.Schema
    end
  
    def handle_errors(conn, err) do
      Logger.error( "#{inspect(err)}")
      conn
    end
  end
  