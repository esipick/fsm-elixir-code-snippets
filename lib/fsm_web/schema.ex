defmodule FlightWeb.GraphQL.Schema do
    use Absinthe.Schema
  
    import_types FlightWeb.GraphQL.Accounts.AccountsTypes
  
    query do
      @desc "say hello"
      field :say_hello, :string do
        resolve fn(_, _, _) -> {:ok, "hello"} end
      end

      import_fields :accounts_queries
    end
  
    mutation do
      import_fields :accounts_mutations
    end
  
    # # exectute changeset error middleware for each mutation
    # def middleware(middleware, _field, %{identifier: :mutation}) do
    #   middleware ++ [Middleware.ChangesetErrors]
    # end
  
    # def middleware(middleware, _field, _object) do
    #   middleware
    # end
  end
  