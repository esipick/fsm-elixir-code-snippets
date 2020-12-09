defmodule FsmWeb.GraphQL.SchoolAssets.SchoolAssetsTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.SchoolAssets.SchoolAssetsResolvers

  #Enum
  # QUERIES
  object :school_assets_queries do
    @desc "List all rooms"
    field :list_rooms, list_of(non_null(:room)) do

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
end