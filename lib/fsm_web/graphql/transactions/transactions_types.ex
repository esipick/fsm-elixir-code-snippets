defmodule FsmWeb.GraphQL.Transactions.TransactionsTypes do
  use Absinthe.Schema.Notation
  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Transactions.TransactionsResolvers

  #Enums
  enum(:transaction_order_by, values: [:desc, :asc])
  enum(:transaction_search_criteria, values: [:first_name, :last_name])
  enum(:transaction_sort_fields, values: [:id, :first_name, :last_name])
  # user roles 1: admin, 2:dispatcher
  # QUERIES
  object :transactions_queries do
    field :all_transaction_history, list_of(:transaction) do
      arg(:page, :integer, default_value: 1)
      arg(:per_page, :integer, default_value: 100)
      arg(:sort_field, :transaction_sort_fields)
      arg(:sort_order, :transaction_order_by)
      arg(:filter, :transactions_filters)

      middleware(Middleware.Authorize, ["admin", "dispatcher", "student", "renter"])
      resolve(&TransactionsResolvers.get_all_transactions/3)
    end
  end

  # MUTATIONS
  object :transactions_mutations do
  end

  # TYPES
  # Enum
  enum(:payment_options, values: [:balance, :cc, :cash, :cheque, :venmo])
  # balance: 0, cc: 1, cash: 2, cheque: 3,venmo: 4
  object :transaction do
    field(:id, :integer)
    field(:paid_by_balance, :integer)
    field(:paid_by_charge, :integer)
    field(:paid_by_cash, :integer)
    field(:paid_by_check, :integer)
    field(:paid_by_venmo, :integer)
    field(:state, :string)
    field(:stripe_charge_id, :string)
    field(:total, :integer)
    field(:type, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:completed_at, :string)
    field(:error_message, :string)
    field(:payment_option, :string)
  end

  input_object :transactions_filters do
    field(:id, :integer)
    field(:start_date, :string)
    field(:status, :string)
    field(:end_date, :string)
    field(:search_criteria, :transaction_search_criteria)
    field(:search_term, :string)
  end
end
