defmodule FsmWeb.GraphQL.School.SchoolTypes do
    use Absinthe.Schema.Notation
  
    alias FsmWeb.GraphQL.Middleware
    alias FsmWeb.GraphQL.School.SchoolResolvers
  
    # Enum

    # QUERIES
    object :school_queries do
      @desc "Get school"
      field :get_school, :school do  
        middleware(Middleware.Authorize)
        resolve(&SchoolResolvers.get_school/3)
      end
    end
  
    # MUTATIONS
  
    # TYPES
    # inputs
    # objects
    object :school do
        field(:name, :string)
        field(:city, :string)
        field(:state, :string)
        field(:zipcode, :string)
        field(:phone_number, :string)
        field(:email, :string)
        field(:website, :string)
        field(:contact_first_name, :string)
        field(:contact_last_name, :string)
        field(:contact_phone_number, :string)
        field(:contact_email, :string)
        field(:timezone, :string)
        field(:student_schedule, :boolean)
        field(:renter_schedule, :boolean)
        field(:sales_tax, :float)
        field(:archived, :boolean)
    end 
  end
