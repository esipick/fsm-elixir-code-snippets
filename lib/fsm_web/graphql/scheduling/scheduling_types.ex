defmodule FsmWeb.GraphQL.Scheduling.SchedulingTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Scheduling.SchedulingResolvers

  enum :appointment_search_criteria, values: [:payer_name]
  enum :appointment_sort_fields, values: [:first_name, :last_name, :email]

  #Enum
  # QUERIES
  object :scheduling_queries do

#    @desc "Get specific appointment"
#      field :appointment, :appointment do
#        middleware Middleware.Authorize
#        resolve &SchedulingResolvers.appointment/3
#      end

#      @desc "Get appointment by id ('admin', 'dispatcher', 'instructor')"
#      field :get_appointment, :appointment do
#        arg :id, non_null(:id)
#        middleware Middleware.Authorize, ["admin", "dispatcher", "instructor"]
#        resolve &SchedulingResolvers.get_appointment/3
#      end

    @desc "List all aircraft appointments ('admin', 'dispatcher')"
    field :list_aircraft_appointments, list_of(non_null(:appointment)) do
      arg :page, :integer, default_value: 1
      arg :per_page, :integer, default_value: 100
      arg :sort_field, :user_sort_fields
      arg :sort_order, :order_by
      arg :filter, :appointment_filters

      middleware Middleware.Authorize, ["admin", "dispatcher"]
      resolve &SchedulingResolvers.list_aircraft_appointments/3
    end

    @desc "List all room appointments ('admin', 'dispatcher')"
    field :list_room_appointments, list_of(non_null(:appointment)) do
      arg :page, :integer, default_value: 1
      arg :per_page, :integer, default_value: 100
      arg :sort_field, :user_sort_fields
      arg :sort_order, :order_by
      arg :filter, :appointment_filters

      middleware Middleware.Authorize, ["admin", "dispatcher"]
      resolve &SchedulingResolvers.list_room_appointments/3
    end

    @desc "List all appointments ('admin', 'dispatcher')"
    field :list_appointments, list_of(non_null(:appointment)) do
      arg :page, :integer, default_value: 1
      arg :per_page, :integer, default_value: 100
      arg :sort_field, :appointment_sort_fields
      arg :sort_order, :order_by
      arg :filter, :appointment_filters

      middleware Middleware.Authorize, ["admin", "dispatcher"]
      resolve &SchedulingResolvers.list_appointments/3
    end
  end

  # MUTATIONS
  object :scheduling_mutations do
     field :create_appointment, :appointment do
       arg :appointment, :appointment_input
       middleware Middleware.Authorize, ["admin", "dispatcher"]
       resolve &SchedulingResolvers.create_appointment/3
     end

     field :edit_appointment, :appointment do
      arg :appointment, :edit_appointment_input
      middleware Middleware.Authorize, ["admin", "dispatcher"]
      resolve &SchedulingResolvers.edit_appointment/3
    end

    field :delete_appointment, :string do
      arg :appointment_id, :integer
      middleware Middleware.Authorize, ["admin", "dispatcher"]
      resolve &SchedulingResolvers.delete_appointment/3
    end
  end
  
  
  # TYPES
  object :appointment do
    field :id, :integer
    field :end_at, :string
    field :start_at, :string
    field :note, :string
    field :payer_name, :string
    field :demo, :boolean
    field :type, :string
    field :status, :string
    field :archived, :boolean

    field :start_tach_time, :integer
    field :end_tach_time, :integer

    field :start_hobbs_time, :integer
    field :end_hobbs_time, :integer

    field :simulator_id, :integer
    field :room_id, :integer

    field :school_id, :integer
    field :instructor_user_id, :integer
    field :owner_user_id, :integer
    field :user_id, :integer
    field :aircraft_id, :integer
    field :transaction_id, :integer
    field :simulator_id, :integer
    field :room_id, :integer
    field :user, :user
    field :instructor, :user
    field :aircraft, :aircraft
    field :room, :room
    field :simulator, :simulator

  end

  input_object :appointment_input do
    field :aircraft_id, :integer 
    field :demo, :boolean
    field :end_at, :string 
    field :instructor_user_id, :integer
    field :note, :string
    field :payer_name, :string 
    field :start_at, :string  
    field :type, :string
    field :user_id, :integer
    field :room_id, :integer
    field :simulator_id, :integer  
  end

  input_object :edit_appointment_input do
    field :id, :integer 
    field :aircraft_id, :integer 
    field :demo, :boolean
    field :end_at, :string 
    field :instructor_user_id, :integer
    field :note, :string
    field :payer_name, :string 
    field :start_at, :string  
    field :user_id, :integer
    field :room_id, :integer
    field :simulator_id, :integer  
  end

  input_object :appointment_filters do
    field :instructor_user_id, :integer
    field :owner_user_id, :integer
    field :user_id, :integer
    field :aircraft_id, :integer
    field :archived, :boolean
    field :school_id, :integer
    field :room_id, :integer
    field :demo, :boolean
    field :upcoming, :boolean
    field :past, :boolean
    field :from, :string
    field :to, :string
    field :type, :string
    field :status, :string
    field :search_criteria, :appointment_search_criteria
    field :search_term, :string
  end
end
  