defmodule FsmWeb.GraphQL.Billing.BillingTypes do
  use Absinthe.Schema.Notation
  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Billing.BillingResolvers

  #Enums
  enum(:transaction_order_by, values: [:desc, :asc])
  enum(:transaction_search_criteria, values: [:first_name, :last_name])
  enum(:transaction_sort_fields, values: [:id, :first_name, :last_name])
  # user roles 1: admin, 2:dispatcher
  # QUERIES
  object :billing_queries do
    field :list_bills, list_of(:invoice) do
      arg(:page, :integer, default_value: 1)
      arg(:per_page, :integer, default_value: 100)
      # arg(:sort_field, :transaction_sort_fields)
      # arg(:sort_order, :transaction_order_by)
      arg(:filter, :transactions_filters)

      middleware(Middleware.Authorize, ["admin", "dispatcher", "student", "renter"])
      resolve(&BillingResolvers.get_all_transactions/3)
    end
  end

  # MUTATIONS
  object :billing_mutations do
    field :add_funds, :string do
      arg :amount, non_null(:string)
      arg :user_id, non_null(:string)
      arg :description, non_null(:string)
      middleware(Middleware.Authorize, ["admin", "dispatcher", "student", "renter"])
      resolve &BillingResolvers.add_funds/3
    end
  end

  # TYPES
  # Enum
  enum(:payment_options, values: [:balance, :cc, :cash, :cheque, :venmo])
  enum(:status, values: [:paid, :pending, :failed])
  # balance: 0, cc: 1, cash: 2, cheque: 3,venmo: 4

  object :invoice do
    field(:id, :integer)
      field(:date, :string)
      field(:total, :integer)
      field(:tax_rate, :string)
      field(:total_tax, :integer)
      field(:total_amount_due, :string)
      field(:status, :status)
      field(:payment_option, :payment_options)
      field(:payer_name, :string)
      field(:demo, :boolean)
      field(:archived, :boolean)
      field(:is_visible, :boolean)
      field(:archived_at, :string)
      field(:appointment_updated_at, :string)
      field(:appointment_id, :integer)
      # field(:aircraft_info, :string)
      field(:session_id, :string)
      field(:transactions, list_of(:transactions))
  end

  object :transactions do
    field(:paid_by_balance, :string)
    field(:paid_by_charge, :string)
    field(:paid_by_cash, :string)
    field(:paid_by_check, :string)
    field(:paid_by_venmo, :string)
    field(:state, :string)
    field(:stripe_charge_id, :string)
    field(:total, :string)
    field(:type, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:completed_at, :string)
    field(:error_message, :string)
    field(:payment_option, :string)
    field(:creator_user_id, :string)  
  end

  input_object :transactions_filters do
    field(:appointment_id, :integer)
    # field(:start_date, :string)
    # field(:status, :string)
    # field(:end_date, :string)
    # field(:search_criteria, :transaction_search_criteria)
    # field(:search_term, :string)
  end
end
