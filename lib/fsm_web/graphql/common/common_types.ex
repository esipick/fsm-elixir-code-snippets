defmodule FsmWeb.GraphQL.Common.CommonTypes do
    use Absinthe.Schema.Notation
  
    alias FsmWeb.GraphQL.Middleware

    enum :order_by, values: [:desc, :asc]

    #Enum
    # QUERIES
    object :common_queries do
    end
  
    # MUTATIONS
    object :common_mutations do
    end
  
    # TYPES
end
  