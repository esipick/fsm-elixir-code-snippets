defmodule FsmWeb.GraphQL.Billing.InvoicesTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Billing.InvoicesResolvers

  #Enum
  # QUERIES
  object :invoices_queries do
    @desc "List all invoice custom line items"
    field :list_custom_line_items, list_of(non_null(:custom_line_item)) do

      middleware Middleware.Authorize
      resolve &InvoicesResolvers.list_custom_line_items/3
    end
  end

  # MUTATIONS
  object :invoices_mutations do
  end

  # TYPES

  object :custom_line_item do
    field :default_rate, :integer
    field :description, :string
    field :taxable, :boolean
    field :deductible, :boolean
  end
end