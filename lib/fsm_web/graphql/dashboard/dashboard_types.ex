defmodule FsmWeb.GraphQL.Dashboard.DashboardTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Dashboard.DashboardResolvers

  #Enum
  # QUERIES
  object :dashboard_queries do
    @desc "List all roles counts ('admin', 'dispatcher')"
    field :list_roles_counts, list_of(non_null(:roles_count)) do
      middleware Middleware.Authorize, ["admin", "dispatcher"]
      resolve &DashboardResolvers.list_roles_counts/3
    end
  end

  # MUTATIONS
  object :dashboard_mutations do
#      field :create_appointment, :appointment do
#        arg :email, non_null(:string)
#        arg :password, non_null(:string)
##        middleware Middleware.Authorize
#        resolve &SchedulingResolvers.create_appointment/3
#      end
  end
  
  # TYPES
  object :roles_count do
    field :title, :string
    field :count, :integer
  end
end
  