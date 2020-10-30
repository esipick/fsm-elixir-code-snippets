defmodule FsmWeb.GraphQL.Transactions.TransactionsTypes do
    use Absinthe.Schema.Notation
    alias FsmWeb.GraphQL.Middleware
    alias FsmWeb.GraphQL.Transactions.TransactionsResolvers
  
    # QUERIES
    object :transactions_queries do
      field :all_transaction_history, list_of(:transaction) do
        middleware Middleware.Authorize
        resolve &TransactionsResolvers.get_all_transactions/3
      end
    end
  
    # MUTATIONS
    object :transactions_mutations do
      
    end
  
    # TYPES
    #Enum
    enum :payment_options, values: [:balance, :cc, :cash, :cheque, :venmo ]
    # balance: 0, cc: 1, cash: 2, cheque: 3,venmo: 4
    object :transaction do
      field :paid_by_balance, :integer 
      field :paid_by_charge, :integer 
      field :paid_by_cash, :integer 
      field :paid_by_check, :integer 
      field :paid_by_venmo, :integer 
      field :state, :string 
      field :stripe_charge_id, :string 
      field :total, :integer 
      field :type, :string 
      field :first_name, :string 
      field :last_name, :string 
      field :email, :string 
      field :completed_at, :string 
      field :error_message, :string 
      field :payment_option, :string
    end

  end
  