defmodule FsmWeb.GraphQL.Accounts.AccountsTypes do
    use Absinthe.Schema.Notation
  
    alias FsmWeb.GraphQL.Middleware
    alias FsmWeb.GraphQL.Accounts.AccountsResolvers

    enum :order_by, values: [:desc, :asc]
    enum :user_search_criteria, values: [:first_name, :last_name, :email]
    enum :user_sort_fields, values: [:first_name, :last_name, :email]

    #Enum
    # QUERIES
    object :accounts_queries do

      @desc "Get user by id."
      field :user, :user do
        middleware Middleware.Authorize
        resolve &AccountsResolvers.get_user/3
      end

      @desc "List all users"
      field :list_users, list_of(non_null(:user)) do
        arg :page, :integer, default_value: 1
        arg :per_page, :integer, default_value: 100
        arg :sort_field, :user_sort_fields
        arg :sort_order, :order_by
        arg :filter, :user_filters

        middleware Middleware.Authorize, [:admin, :dispatcher]
        resolve &AccountsResolvers.list_users/3
      end
    end
  
    # MUTATIONS
    object :accounts_mutations do
      field :login, :session do
        arg :email, non_null(:string)
        arg :password, non_null(:string)
#        middleware Middleware.Authorize
        resolve &AccountsResolvers.login/3
      end
    end
  
    # TYPES
    object :session do
        field :user, non_null(:user)
        field :token, non_null(:string)
    end

    object :user do
      field :email, :string
  
      field :date_of_birth, :string
      field :gender, :string  
      field :emergency_contact_no, :string  
      field :d_license_no, :string  
      field :d_license_expires_at, :string  
      field :d_license_country, :string  
      field :d_license_state, :string  
      field :passport_no, :string  
      field :passport_expires_at, :string 
      field :passport_country, :string  
      field :passport_issuer_name, :string  
      field :last_faa_flight_review_at, :string 
      field :renter_policy_no, :string  
      field :renter_insurance_expires_at, :string 
  
      field :pilot_current_certificate, list_of(:string) 
      field :pilot_aircraft_categories, list_of(:string) 
      field :pilot_class, list_of(:string)  
      field :pilot_ratings, list_of(:string)  
      field :pilot_endorsements, list_of(:string)
      field :pilot_certificate_number, :string  
      field :pilot_certificate_expires_at, :string 
  
      field :first_name, :string  
      field :last_name, :string  
      field :balance, :integer 
      field :phone_number, :string  
      field :address_1, :string
      field :city, :string  
      field :state, :string  
      field :zipcode, :string  
      field :flight_training_number, :string  
      field :medical_rating, :integer  
      field :medical_expires_at, :string
      field :certificate_number, :string  
      field :billing_rate, :string
      field :pay_rate, :string
      field :awards, :string  
      field :archived, :boolean
      field :stripe_customer_id, :string  
      field :avatar, :string
  end

  input_object :user_filters do
    field :archived, :boolean
    field :search_criteria, :user_search_criteria
    field :search_term, :string
  end
end
  