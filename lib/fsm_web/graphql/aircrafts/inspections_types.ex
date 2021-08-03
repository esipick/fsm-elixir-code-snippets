defmodule FsmWeb.GraphQL.Aircrafts.InspectionsTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Aircrafts.InspectionsResolvers

  enum(:field_type, values: [:int, :string, :date, :float])
  enum(:inspection_type, values: ["IFR", "VFR"])
  enum(:date_tach, values: [:date, :tach])
  enum(:inspection_sort_fields, values: [:updated, :is_completed, :name, :completed_at])

  # Inspections Queries

  object :inspections_queries do
    @desc "Get inspections by aircraft_id"
    field :get_inspections, list_of(:inspection) do
      arg(:aircraft_id, non_null(:id))
      arg(:page, :integer, default_value: 1)
      arg(:per_page, :integer, default_value: 100)
      arg(:filter, :inspection_filter)
      resolve(&InspectionsResolvers.get_inspections/3)
    end

    @desc "Get inspection by inspection_id"
    field :get_inspection, :inspection do
      arg(:inspection_id, non_null(:id))
      resolve(&InspectionsResolvers.get_inspection/3)
    end
  end

  # Inspections Mutations

  object :inspections_mutations do
    @desc "Add inspection"
    field :add_inspection, :inspection do
      arg(:inspection_input, non_null(:inspection_input))
      middleware(Middleware.Authorize, ["admin"])
      resolve(&InspectionsResolvers.add_inspection/3)
    end

    @desc "Update inspection"
    field :update_inspection, :boolean do
      arg(:id, non_null(:id))
      arg(:data, list_of(non_null(:inspection_keyval)))
      middleware(Middleware.Authorize, ["admin"])
      resolve(&InspectionsResolvers.update_inspection/3)
    end

    @desc "Complete inspection"
    field :complete_inspection, :inspection do
      arg(:completion_input, non_null(:completion_input))
      middleware(Middleware.Authorize, ["admin"])
      resolve(&InspectionsResolvers.complete_inspection/3)
    end

    @desc "Delete inspection"
    field :delete_inspection, :inspection do
      arg(:id, non_null(:id))
      middleware(Middleware.Authorize, ["admin"])
      resolve(&InspectionsResolvers.delete_inspection/3)
    end
  end

  # Inspection Types

  object :inspection do
    field(:id, :integer)
    field(:name, :string)
    field(:type, :inspection_type)
    field(:updated, :boolean)
    field(:is_repeated, :boolean)
    field(:is_completed, :boolean)
    field(:is_system_defined, :boolean)
    field(:repeat_every_days, :integer)
    field(:date_tach, :date_tach)
    field(:completed_at, :naive_datetime)
    field(:inspection_data, list_of(non_null(:inspection_field)))
    field(:attachments, list_of(non_null(:attachment)))
  end

  object :inspection_field do
    field(:name, :string)
    field(:value, :string)
    field(:type, :string)
    field(:class_name, :string)
    field(:sort, :integer)
  end

  input_object :inspection_input do
    field(:name, :string)
    field(:type, :inspection_type)
    field(:updated, :boolean)
    field(:aircraft_id, :integer)
    field(:date_tach, :date_tach)
    field(:inspection_data, list_of(non_null(:inspection_data_input)))
  end

  input_object :inspection_data_input do
    field(:name, :string)
    field(:value, :string)
    field(:type, :field_type)
    field(:class_name, :string)
    field(:sort, :integer)
  end

  input_object :inspection_filter do
    field(:name, :string)
    field(:type, :string)
    field(:note, :string)
    field(:updated, :boolean)
    field(:aircraft_id, :integer)
    field(:sort_order, :order_by)
    field(:sort_field, :inspection_sort_fields)
    field(:completed, :boolean)
  end

  input_object :inspection_keyval do
    field(:name, :string)
    field(:value, :string)
  end

  input_object :completion_input do
    field(:inspection_id, non_null(:id))
    field(:note, :string)
    field(:next_inspection, :naive_datetime)
    field(:is_repeated, :boolean)
    field(:repeat_every_days, :integer)
    field(:tach_hours, :float)
  end

end
