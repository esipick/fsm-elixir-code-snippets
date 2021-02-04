defmodule FsmWeb.GraphQL.Billing.BillingTypes do
  use Absinthe.Schema.Notation
  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Billing.BillingResolvers

  #Enums
  enum(:transaction_order_by, values: [:desc, :asc])
  enum(:charge_payment_method, values: [:cash, :cc])
  enum(:transaction_search_criteria, values: [:first_name, :last_name])
  enum(:transaction_sort_fields, values: [:id, :first_name, :last_name])
  # user roles 1: admin, 2:dispatcher
  # QUERIES
  object :billing_queries do
    field :list_bills, :billing_data do
      arg(:page, :integer, default_value: 1)
      arg(:per_page, :integer, default_value: 100)
      # arg(:sort_field, :transaction_sort_fields)
      arg(:sort_order, :transaction_order_by)
      arg(:filter, :transactions_filters)

      middleware(Middleware.Authorize, ["admin", "dispatcher","instructor", "student", "renter"])
      resolve(&BillingResolvers.get_all_transactions/3)
    end

    field :fetch_card, :card do
      arg(:user_id, :integer)

      middleware(Middleware.Authorize, ["admin", "dispatcher","instructor", "student", "renter"])
      resolve(&BillingResolvers.fetch_card/3)
    end
  end

  # MUTATIONS
  object :billing_mutations do
    field :add_funds, :string do
      arg :amount, non_null(:string)
      arg :payment_method, non_null(:charge_payment_method)
      arg :user_id, non_null(:string)
      arg :description, non_null(:string)
      middleware(Middleware.Authorize, ["admin", "dispatcher", "instructor" , "student", "renter"])
      resolve &BillingResolvers.add_funds/3
    end

    field :add_credit_card, :string do
      arg :stripe_token, non_null(:string)
      arg :user_id, non_null(:string)
      middleware(Middleware.Authorize, ["admin", "dispatcher", "renter", "instructor", "student"])
      resolve &BillingResolvers.add_credit_card/3
    end


    field :create_invoice, :invoice do
      arg :pay_off, non_null(:boolean)
      arg :invoice, non_null(:create_invoice_input)
      middleware(Middleware.Authorize, ["admin", "dispatcher", "renter", "instructor", "student" ])
      resolve &BillingResolvers.create_invoice/3
    end

    field :update_invoice, :invoice do
      arg :pay_off, non_null(:boolean)
      arg :invoice, non_null(:update_invoice_input)
      middleware(Middleware.Authorize, ["admin", "dispatcher", "renter", "instructor", "student"])
      resolve &BillingResolvers.update_invoice/3
    end
  end

  # TYPES
  # Enum
  enum(:payment_options, values: [:balance, :cc, :cash, :cheque, :venmo])
  enum(:status, values: [:paid, :pending, :failed])
  # balance: 0, cc: 1, cash: 2, cheque: 3,venmo: 4

  object :card do
    field(:address_zip, :string)
    field(:address_zip_check, :string)
    field(:brand, :string)
    field(:country, :string)
    field(:cvc_check, :string)
    field(:exp_year, :string)
    field(:exp_month, :string)
    field(:last4, :string)
    field(:object, :string)
  end

  object :billing_data do
    field(:invoices, list_of(:invoice))
    field(:page, :integer)

  end

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
      field(:inserted_at, :string)
      field(:appointment_id, :integer)
      # field(:aircraft_info, :string)
      field(:session_id, :string)
      field(:transactions, list_of(:transactions))
      field(:line_items, list_of(:line_item))
  end

  object :transactions do
    field(:id, :integer)
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
    field(:payment_option, :string)  do
      resolve(&BillingResolvers.invoice_payment_option_enum/3)
    end
    field(:creator_user_id, :string)
    field(:inserted_at, :string)
  end

  object :line_item do
    field(:aircraft_id, :integer)
    field(:tail_number, :string)
    field(:model, :string)
    field(:make, :string)
    field(:aircraft_simulator_name, :string)
    field(:simulator, :boolean)
    field(:amount, :integer)
    field(:deductible, :boolean)
    field(:description, :string)
    field(:enable_rate, :boolean)
    field(:hobbs_end, :integer)
    field(:hobbs_start, :integer)
    field(:id, :string)
    field(:persist_rate, :boolean)
    field(:quantity, :float)
    field(:rate, :integer)
    field(:tach_end, :integer)
    field(:tach_start, :integer)
    field(:taxable, :boolean)
    field(:type, :string)
    field(:instructor_user_id, :integer)
    field(:instructor_name, :string)
  end

  input_object :line_item_input do
    field(:aircraft_id, :integer)
    field(:room_id, :integer)
    field(:amount, :integer)
    field(:deductible, :boolean)
    field(:description, :string)
    field(:enable_rate, :boolean)
    field(:hobbs_end, :integer)
    field(:hobbs_start, :integer)
    field(:id, :string)
    field(:persist_rate, :boolean)
    field(:quantity, :float)
    field(:rate, :integer)
    field(:tach_end, :integer)
    field(:tach_start, :integer)
    field(:taxable, :boolean)
    field(:type, :string)
    field(:instructor_user_id, :integer)
  end

  input_object :create_invoice_input do
    field(:appointment_id, :integer)
    field(:stripe_token, :string)
    field(:date, :string)
    field(:ignore_last_time, :boolean)
    field(:demo, :boolean)
    field(:is_visible, :boolean)
    field(:payer_name, :string)
    field(:payment_option, :payment_options)
    field(:tax_rate, :integer)
    field(:total, :integer)
    field(:total_amount_due, :integer)
    field(:total_tax, :integer)
    field(:user_id, :integer)
    field(:line_items, list_of(:line_item_input))
  end

  input_object :update_invoice_input do
    field(:id, :integer)
    field(:appointment_id, :integer)
    field(:stripe_token, :string)
    field(:date, :string)
    field(:ignore_last_time, :boolean)
    field(:is_visible, :boolean)
    field(:demo, :boolean)
    field(:payer_name, :string)
    field(:payment_option, :payment_options)
    field(:tax_rate, :integer)
    field(:total, :integer)
    field(:total_amount_due, :integer)
    field(:total_tax, :integer)
    field(:user_id, :integer)
    field(:line_items, list_of(:line_item_input))
  end

  input_object :transactions_filters do
    field(:appointment_id, :integer)
    field(:id, :integer)
    # field(:start_date, :string)
    # field(:status, :string)
    # field(:end_date, :string)
    # field(:search_criteria, :transaction_search_criteria)
    # field(:search_term, :string)
  end
end
