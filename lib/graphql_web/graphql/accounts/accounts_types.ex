defmodule FlightWeb.GraphQL.Accounts.AccountsTypes do
    use Absinthe.Schema.Notation
  
    alias FlightWeb.GraphQL.Accounts.AccountsResolvers
  
    #Enum
    # QUERIES
    object :accounts_queries do
    end
  
    # MUTATIONS
    object :accounts_mutations do
      field :login, :session do
        arg :email_or_id, non_null(:string)
        arg :password, non_null(:string)
        resolve &AccountsResolvers.login/3
      end
    end
  
    # TYPES
    object :session do
        field :user, non_null(:string)
        field :token, non_null(:string)
    end
  end
  