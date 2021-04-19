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
    field :latest_app_version, non_null(:app_version) do
      resolve &DashboardResolvers.latest_app_version/3
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

  object :app_version do
    field :version, non_null(:string)
    field :int_version, non_null(:integer)
    field :android_version, non_null(:string)
    field :android_int_version, non_null(:integer)
    field :ios_version, non_null(:string)
    field :ios_int_version, non_null(:integer)
    field :created_at, non_null(:string)
    field :updated_at, non_null(:string)
  end
end
  