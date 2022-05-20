defmodule FsmWeb.GraphQL.Alerts.AlertsTypes do
    use Absinthe.Schema.Notation

    alias FsmWeb.GraphQL.Middleware
    alias FsmWeb.GraphQL.Alerts.AlertsResolvers

    enum :alert_search_criteria, values: [:title, :description]
    enum :alert_code_enum, values: [:squawk, :appointment, :unavailability, :aircraft, :payment]
    enum :alert_priority_enum, values: [:top, :high, :medium, :low]
    enum :alert_sort_fields, values: [:title, :description, :code, :priority, :is_read, :created_at, :updated_at]

    #Enum
    # QUERIES
    object :alerts_queries do

      @desc "Get alert by id ('all')"
      field :get_notification_alert, :alert do
        arg :id, non_null(:id)
        middleware Middleware.Authorize
        resolve &AlertsResolvers.get_alert/3
      end

      @desc "List notification alerts ('all')"
      field :list_notification_alerts, :alert_data do
        arg :page, :integer, default_value: 1
        arg :per_page, :integer, default_value: 100
        arg :sort_field, :alert_sort_fields
        arg :sort_order, :order_by, default_value: :desc
        arg :filter, :alert_filters

        middleware Middleware.Authorize
        resolve &AlertsResolvers.list_alerts/3
      end
    end

    # MUTATIONS
    object :alerts_mutations do
      @desc "Mark notification alerts as read/unread"
      field :mark_notification_alerts, :boolean do
        arg :alert_ids, list_of(non_null(:id))
        arg :is_read, non_null(:boolean)
        middleware(Middleware.Authorize, ["admin", "instructor", "student", "renter", "dispatcher", "mechanic"])
        resolve(&AlertsResolvers.mark_notification_alerts/3)
      end

      @desc "Delete notification alerts"
      field :delete_notification_alerts, :boolean do
        arg :alert_ids, list_of(non_null(:id))
        middleware(Middleware.Authorize, ["admin", "instructor", "student", "renter", "dispatcher", "mechanic"])
        resolve(&AlertsResolvers.delete_notification_alerts/3)
      end

      @desc "Mark all notification alerts as read/unread"
      field :mark_all_notification_alerts, :boolean do
        arg :is_read, non_null(:boolean)
        middleware(Middleware.Authorize, ["admin", "instructor", "student", "renter", "dispatcher", "mechanic"])
        resolve(&AlertsResolvers.mark_all_notification_alerts/3)
      end

      @desc "Delete all notification alerts"
      field :delete_all_notification_alerts, :boolean do
        middleware(Middleware.Authorize, ["admin", "instructor", "student", "renter", "dispatcher", "mechanic"])
        resolve(&AlertsResolvers.delete_all_notification_alerts/3)
      end
    end

    # TYPES

    object :alert_data do
      field :alerts, list_of(non_null(:alert))
      field :page, :integer
    end

    object :alert do
      field :id, :integer
      field :title, :string
      field :description, :string
      field :priority, :alert_priority_enum
      field :code, :alert_code_enum
      field :receiver_id, :integer
      field :sender_id, :integer
      field :is_read, :boolean
      field :archived, :boolean
      field :additional_info, :json
      field :school_id, :integer
      field :created_at, :naive_datetime
      field :updated_at, :naive_datetime
    end

    object :alert_input do
      field :id, non_null(:id)
      field :is_read, :boolean
    end

    input_object :alert_filters do
      field :title, :string
      field :code, :alert_code_enum
      field :priority, :integer
      field :is_read, :boolean
      field :search_criteria, :alert_search_criteria
      field :search_term, :string
    end
end
