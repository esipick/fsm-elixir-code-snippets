defmodule FsmWeb.GraphQL.Squawks.SquawksTypes do
    use Absinthe.Schema.Notation

    alias FbossWeb.GraphQL.Squawks.SquawksResolvers

    enum :squawk_severity, values: [:monitor, :warning, :grounded]
    enum :system_affected, values: [:fuselage, :cockpit ,:wing, :tail, :engine, :propeller, :landing_gear]
    # Queries
    object :squawks_queries do
        @desc "Get Squawk"
        field :get_squawk, :squawk_data do
            arg :inspection_id, non_null(:id)
            resolve &AquawksResolvers.get_squawk/3
        end

        @desc "Get squawks"
        field :get_squawks, :squawk_data do
            resolve &SquawksResolvers.get_squawks/3
        end
    end
    object :squawks_mutations do
        @desc "Add squawk"
        field :add_squawk, :squawk do
            arg :squawk_input, non_null(:squawk_input)
            arg :squawk_image_input, :squawk_image_input
            resolve &SquawksResolvers.add_squawk/3
        end

        @desc "Update squawk"
        field :update_squawk, :squawk do
            arg :id, non_null(:id)
            arg :squawk_input, non_null(:squawk_input)
            resolve &SquawksResolvers.update_squawk/3
        end

        @desc "Delete squawk"
        field :delete_squawk, :boolean do
            arg :id, non_null(:id)
            resolve &SquawksResolvers.delete_squawk/3
        end

        @desc "Add squawk image"
        field :add_squawk_image, :squawk_image do
            arg :squawk_image_input, non_null(:squawk_image_input)
            resolve &SquawksResolvers.add_squawk_image/3
        end

        @desc "Delete squawk image"
        field :delete_squawk_image, :squawk_image do
            arg :id, non_null(:id)
            resolve &SquawksResolvers.delete_squawk_image/3
        end

        @desc "resolve squawk image"
        field :resolve_squawk, :squawk_image do
            arg :id, non_null(:id)
            resolve &SquawksResolvers.resolve_squawk/3
        end
    end


    input_object :squawk_input do
        field :title, :string
        field :severity, :squawk_severity
        field :description, :string
        field :system_affected, :system_affected

    end

    input_object :squawk_image_input do
        field :url, :string
        field :squawk_id, :integer
        field :file_name, :string
        field :file_extension, :string
        field :size_in_bytes, :integer
    end

    # Types

    object :squawk_image do
        field :id, :integer
        field :url, non_null(:string)
        field :file_name, non_null(:string)
        field :file_extension, non_null(:string)
        field :size_in_bytes, non_null(:integer)
    end

    object :squawk do
        field :id, :integer
        field :title, :string
        field :severity, :squawk_severity
        field :description, :string
        field :system_affected, :system_affected
        field :resolved, :boolean
        field :attachments, list_of(:squawk_image)
    end


    object :squawk_data do
        field :squawks, list_of(:squawk)
    end


end