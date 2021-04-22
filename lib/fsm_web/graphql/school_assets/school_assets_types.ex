defmodule FsmWeb.GraphQL.SchoolAssets.SchoolAssetsTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.SchoolAssets.SchoolAssetsResolvers

  #Enum
  enum :room_search_criteria, values: [:location, :resources]
  enum :room_sort_fields, values: [:location, :resources, :capacity, :rate_per_hour, :block_rate_per_hour, :inserted_at]

  # QUERIES
  object :school_assets_queries do
    @desc "List all rooms"
    field :list_rooms, list_of(non_null(:room)) do
      arg :page, :integer, default_value: 1
      arg :per_page, :integer, default_value: 100
      arg :sort_field, :room_sort_fields
      arg :sort_order, :order_by
      arg :filter, :room_filters
      middleware Middleware.Authorize
      resolve &SchoolAssetsResolvers.list_rooms/3
    end
  end

  # MUTATIONS
  object :school_assets_mutations do
  end

  # TYPES

  object :room do
    field :id, :integer
    field :capacity, :integer
    field :location, :string
    field :block_rate_per_hour, :integer
    field :rate_per_hour, :integer
    field :resources, :string
    field :archived, :boolean
  end

  input_object :room_filters do
    field :capacity, :integer
    field :archived, :boolean
    field :search_criteria, :room_search_criteria
    field :search_term, :string
  end

end