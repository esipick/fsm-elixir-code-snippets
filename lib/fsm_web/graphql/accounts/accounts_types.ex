defmodule FsmWeb.GraphQL.Accounts.AccountsTypes do
    use Absinthe.Schema.Notation

    alias FsmWeb.GraphQL.Middleware
    alias FsmWeb.GraphQL.Accounts.AccountsResolvers

    enum :user_search_criteria, values: [:first_name, :last_name, :email, :full_name]
    enum :roles, values: ["admin", "dispatcher","student", "renter", "instructor", "mechanic"]
    enum :user_sort_fields, values: [:first_name, :last_name, :email]
    enum :user_gender, values: ["Male", "Female"]

    #Enum
    # QUERIES
    object :accounts_queries do

      @desc "Get current user"
      field :user, :user do
        middleware Middleware.Authorize
        resolve &AccountsResolvers.get_current_user/3
      end

      @desc "Get user by id ('admin', 'dispatcher', 'instructor', 'admin')"
      field :get_user, :user do
        arg :id, non_null(:id)
        middleware Middleware.Authorize, ["admin", "dispatcher", "instructor", "mechanic"]
        resolve &AccountsResolvers.get_user/3
      end

      @desc "List all users ('admin', 'dispatcher')"
      field :list_users, list_of(non_null(:user)) do
        arg :page, :integer, default_value: 1
        arg :per_page, :integer, default_value: 100
        arg :sort_field, :user_sort_fields
        arg :sort_order, :order_by
        arg :filter, :user_filters

        middleware Middleware.Authorize, ["admin", "dispatcher", "renter", "instructor", "student", "mechanic"]
        resolve &AccountsResolvers.list_users/3
      end

      @desc "List all instructors"
      field :list_instructors, list_of(non_null(:user)) do
        arg :page, :integer, default_value: 1
        arg :per_page, :integer, default_value: 100
        arg :sort_field, :user_sort_fields
        arg :sort_order, :order_by
        arg :filter, :user_filters

        middleware Middleware.Authorize, ["admin", "dispatcher", "renter", "instructor", "student", "mechanic"]
        resolve &AccountsResolvers.list_instructors/3
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

      field :forgot_password, :string do
        arg :email, non_null(:string)
#        middleware Middleware.Authorize
        resolve &AccountsResolvers.forgot_submit/3
      end

      field :change_password, :user do
        arg :password, non_null(:string)
        arg :new_password, non_null(:string)
        middleware Middleware.Authorize
        resolve &AccountsResolvers.change_password/3
      end

      field :create_push_token, :boolean do
        arg :user_id, non_null(:integer)
        arg :token, non_null(:string)
        arg :platform, non_null(:string)
        middleware Middleware.Authorize
        resolve &AccountsResolvers.create_push_token/3
      end

      field :delete_push_token, :boolean do
        arg :user_id, non_null(:integer)
        arg :token, non_null(:string)
        arg :platform, non_null(:string)
        middleware Middleware.Authorize
        resolve &AccountsResolvers.delete_push_token/3
      end

      field :verify_reset_password_token, :session do
        arg :token, non_null(:string)
#        middleware Middleware.Authorize
        resolve &AccountsResolvers.reset/3
      end

      field :reset_password, :user do
        arg :token, non_null(:string)
        arg :password, non_null(:string)
        arg :password_confirmation, non_null(:string)
#        middleware Middleware.Authorize
        resolve &AccountsResolvers.reset_submit/3
      end

      field :create_user, :user do
        arg :user_input, non_null(:user_input)
        arg :role_slug, non_null(:roles)
        middleware Middleware.Authorize, ["admin", "dispatcher", "instructor"]
        resolve &AccountsResolvers.create_user/3
      end

      field :update_user, :user do
        arg :user_input, non_null(:user_input)
        arg :role_slugs, list_of(non_null(:roles))
        arg :id, non_null(:integer)
        middleware Middleware.Authorize
        resolve &AccountsResolvers.update_user/3
      end
    end

    # TYPES
    object :session do
        field :user, non_null(:user)
        field :token, non_null(:string)
    end

    object :user do
      field :id, :integer
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
      field :notes, :string
      field :archived, :boolean
      field :stripe_customer_id, :string
      field :avatar, :avatar_type
      field :roles, list_of(:string)
      field :school, :school
    end

  object :avatar_type do
    field :original, :string
    field :thumb, :string
  end

  input_object :user_filters do
    field :archived, :boolean
    field :assigned, :boolean
    field :search, list_of(:search_input)
    field :roles, list_of(:roles)
  end

  input_object :search_input do
    field :search_criteria, :user_search_criteria
    field :search_term, :string
  end

  input_object :user_input do
    field :email, :string

    field :date_of_birth, :string
    field :gender, :user_gender
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
    field :avatar, :upload
    field :avatar_binary, :string
    field :notes, :string
  end

  object :input_avatar do
    field :content_type, :string
    field :filename, :string
    field :path, :string
  end
end
