defmodule FsmWeb.GraphQL.Schema do
    use Absinthe.Schema
  
    import_types FsmWeb.GraphQL.Accounts.AccountsTypes
    import_types FsmWeb.GraphQL.Billing.BillingTypes
    import_types FsmWeb.GraphQL.Documents.DocumentsTypes
    import_types FsmWeb.GraphQL.Scheduling.SchedulingTypes
    import_types FsmWeb.GraphQL.Dashboard.DashboardTypes
    import_types FsmWeb.GraphQL.Aircrafts.AircraftsTypes
    import_types FsmWeb.GraphQL.Billing.InvoicesTypes
    import_types FsmWeb.GraphQL.SchoolAssets.SchoolAssetsTypes
    import_types FsmWeb.GraphQL.School.SchoolTypes
    import_types FsmWeb.GraphQL.Common.CommonTypes
    import_types Absinthe.Plug.Types
    import_types Absinthe.Type.Custom

    query do
      @desc "say hello"
      field :say_hello, :string do
        resolve fn(_, _, _) -> {:ok, "hello"} end
      end

      import_fields :accounts_queries
      import_fields :billing_queries
      import_fields :documents_queries
      import_fields :scheduling_queries
      import_fields :dashboard_queries
      import_fields :aircrafts_queries
      import_fields :invoices_queries
      import_fields :school_assets_queries
      import_fields :school_queries
      import_fields :common_queries
    end
  
    mutation do
      import_fields :accounts_mutations
      import_fields :billing_mutations
      import_fields :documents_mutations
      import_fields :scheduling_mutations
      import_fields :dashboard_mutations
      import_fields :aircrafts_mutations
      import_fields :invoices_mutations
      import_fields :school_assets_mutations
      import_fields :common_mutations
    end
  
    # # exectute changeset error middleware for each mutation
    # def middleware(middleware, _field, %{identifier: :mutation}) do
    #   middleware ++ [Middleware.ChangesetErrors]
    # end
  
    # def middleware(middleware, _field, _object) do
    #   middleware
    # end
  end
  