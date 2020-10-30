defmodule FsmWeb.GraphQL.Schema do
    use Absinthe.Schema
  
    import_types FsmWeb.GraphQL.Accounts.AccountsTypes
    import_types FsmWeb.GraphQL.Transactions.TransactionsTypes
    
    query do
      @desc "say hello"
      field :say_hello, :string do
        resolve fn(_, _, _) -> {:ok, "hello"} end
      end

      import_fields :accounts_queries
      import_fields :transactions_queries
    end
  
    mutation do
      import_fields :accounts_mutations
      import_fields :transactions_mutations
    end
  
    # # exectute changeset error middleware for each mutation
    # def middleware(middleware, _field, %{identifier: :mutation}) do
    #   middleware ++ [Middleware.ChangesetErrors]
    # end
  
    # def middleware(middleware, _field, _object) do
    #   middleware
    # end
  end
  