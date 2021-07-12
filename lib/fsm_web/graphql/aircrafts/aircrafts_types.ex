defmodule FsmWeb.GraphQL.Aircrafts.AircraftsTypes do
    use Absinthe.Schema.Notation
  
    alias FsmWeb.GraphQL.Middleware
    alias FsmWeb.GraphQL.Aircrafts.AircraftsResolvers

    enum :aircraft_search_criteria, values: [:name, :make, :model, :serial_number, :equipment, :tail_number]
    enum :aircraft_sort_fields, values: [:name, :make, :model, :serial_number, :equipment, :tail_number]

    #Enum
    # QUERIES
    object :aircrafts_queries do

      @desc "Get aircraft by id ('all')"
      field :get_aircraft, :aircraft do
        arg :id, non_null(:id)
        middleware Middleware.Authorize
        resolve &AircraftsResolvers.get_aircraft/3
      end

      @desc "List all aircrafts ('all')"
      field :list_aircrafts, :aircraft_data do
        arg :page, :integer, default_value: 1
        arg :per_page, :integer, default_value: 100
        arg :sort_field, :user_sort_fields
        arg :sort_order, :order_by
        arg :filter, :aircraft_filters

        middleware Middleware.Authorize
        resolve &AircraftsResolvers.list_aircrafts/3
      end
    end
  
    # MUTATIONS
    object :aircrafts_mutations do
    end
  
    # TYPES

    object :aircraft_data do
      field :aircrafts, list_of(non_null(:aircraft))
      field :page, :integer
    end

    object :aircraft do
      field :id, :integer
      field :ifr_certified, :boolean
      field :last_tach_time, :integer
      field :last_hobbs_time, :integer
      field :name, :string
      field :make, :string
      field :model, :string
      field :block_rate_per_hour, :integer
      field :rate_per_hour, :integer
      field :serial_number, :string
      field :equipment, :string
      field :simulator, :boolean
      field :tail_number, :string
      field :archived, :boolean
      field :blocked, :boolean
      field :school_id, :integer
      field :squawks, list_of(non_null(:squawk))
      field :inspections, list_of(non_null(:inspection))
    end

    object :simulator do
      field :id, :integer
      field :ifr_certified, :boolean
      field :last_tach_time, :integer
      field :last_hobbs_time, :integer
      field :name, :string
      field :make, :string
      field :model, :string
      field :block_rate_per_hour, :integer
      field :rate_per_hour, :integer
      field :serial_number, :string
      field :equipment, :string
      field :simulator, :boolean
      field :tail_number, :string
      field :archived, :boolean
      field :blocked, :boolean
      field :school_id, :integer
      field :inspections, list_of(non_null(:inspection))
    end

    object :inspection do
      field(:name, :string)
      field(:type, :string)
      field(:date_value, :string)
      field(:number_value, :integer)
    end

  input_object :aircraft_filters do
    field :id, :integer
    field :archived, :boolean
    field :assigned, :boolean
    field :ifr_certified, :boolean
    field :simulator, :boolean
    field :blocked, :boolean
    field :search_criteria, :aircraft_search_criteria
    field :search_term, :string
  end
end
  