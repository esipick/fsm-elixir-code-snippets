defmodule FsmWeb.GraphQL.Scheduling.SchedulingTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Middleware
  alias FsmWeb.GraphQL.Scheduling.SchedulingResolvers

  enum :appointment_search_criteria, values: [:payer_name]
  enum :belongs, values: ["Instructor", "Simulator", "Room", "Aircraft", "Mechanic"]
  enum :appointment_sort_fields, values: [:first_name, :last_name, :email]
  enum :repeat_type, values: [:weekly, :monthly]

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

    @desc "List all aircraft appointments"
    field :list_aircraft_appointments, list_of(non_null(:appointment)) do
      arg :page, :integer, default_value: 1
      arg :per_page, :integer, default_value: 100
      arg :sort_field, :user_sort_fields
      arg :sort_order, :order_by
      arg :filter, :appointment_filters

      middleware Middleware.Authorize
      resolve &SchedulingResolvers.list_aircraft_appointments/3
    end

    @desc "List all room appointments"
    field :list_room_appointments, list_of(non_null(:appointment)) do
      arg :page, :integer, default_value: 1
      arg :per_page, :integer, default_value: 100
      arg :sort_field, :user_sort_fields
      arg :sort_order, :order_by
      arg :filter, :appointment_filters

      middleware Middleware.Authorize
      resolve &SchedulingResolvers.list_room_appointments/3
    end

    @desc "List all appointments ('all')"
    field :list_appointments, list_of(non_null(:appointment)) do
      arg :page, :integer, default_value: 1
      arg :per_page, :integer, default_value: 1000
      arg :sort_field, :appointment_sort_fields
      arg :sort_order, :order_by
      arg :filter, :appointment_filters

      middleware Middleware.Authorize
      resolve &SchedulingResolvers.list_appointments/3
    end

    @desc "List all unavailabilities"
    field :list_unavailabilities, list_of(non_null(:unavailability)) do
      arg :filter, :unavailability_filters

      middleware Middleware.Authorize
      resolve &SchedulingResolvers.list_unavailabilities/3
    end

    @desc "Appointment ICS file"
    field :appointment_ics_url, :string do
      arg :appointment_id, non_null(:id)

      middleware Middleware.Authorize
      resolve &SchedulingResolvers.appointment_ics_url/3
    end
  end

  # MUTATIONS
  object :scheduling_mutations do
    field :create_unavailability, :unavailability do
      arg :unavailability, :unavailability_input
      middleware Middleware.Authorize
      resolve &SchedulingResolvers.create_unavailability/3
    end

    field :edit_unavailability, :unavailability do
      arg :id, non_null(:integer)
      arg :unavailability, :unavailability_input
      middleware Middleware.Authorize
      resolve &SchedulingResolvers.edit_unavailability/3
    end

    field :delete_unavailability, :boolean do
      arg :id, non_null(:integer)
      middleware Middleware.Authorize
      resolve &SchedulingResolvers.delete_unavailability/3
    end

    field :create_appointment, :appointment do
      arg :appointment, :appointment_input
      middleware Middleware.Authorize
      resolve &SchedulingResolvers.create_appointment/3
    end

    field :create_recurring_appointment, :recurring_appointment do
      arg :appointment, :appointment_input
      middleware Middleware.Authorize
      resolve &SchedulingResolvers.create_recurring_appointment/3
    end

     field :edit_appointment, :appointment do
      arg :appointment, :edit_appointment_input
      middleware Middleware.Authorize
      resolve &SchedulingResolvers.edit_appointment/3
    end

    field :delete_appointment, :string do
      arg :appointment_id, :integer
      middleware Middleware.Authorize
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

    field :inst_start_at, :naive_datetime
    field :inst_end_at, :naive_datetime

    field :simulator_id, :integer
    field :room_id, :integer

    field :school_id, :integer
    field :instructor_user_id, :integer
    field :mechanic_user_id, :integer
    field :owner_user_id, :integer
    field :user_id, :integer
    field :aircraft_id, :integer
    field :transaction_id, :integer
    field :simulator_id, :integer
    field :room_id, :integer
    field :user, :user
    field :instructor, :user
    field :mechanic, :user
    field :aircraft, :aircraft
    field :room, :room
    field :simulator, :simulator

  end

  object :unavailability do
    field :id, :integer
    field :simulator_id, :integer
    field :room_id, :integer

    field :school_id, :integer
    field :instructor_user_id, :integer
    field :owner_user_id, :integer
    field :user_id, :integer
    field :aircraft_id, :integer


    field :available, :boolean
    field :type, :string
    field :note, :string
    field :end_at, :string
    field :start_at, :string
    field :belongs, :string

    field(:simulator_id, :integer)
    field(:room_id, :integer)
#    field :user, :user
#    field :instructor, :user
#    field :aircraft, :aircraft
#    field :room, :room
#    field :simulator, :simulator

  end

  object :recurring_appointment do
    field :human_errors, :json
  end

  input_object :unavailability_input do
    field :simulator_id, :integer
    field :room_id, :integer

    field :instructor_user_id, :integer
    field :aircraft_id, :integer
    field :belongs, :belongs
    field :note, :string
    field :end_at, :string
    field :start_at, :string
  end

  input_object :appointment_input do
    field :aircraft_id, :integer
    field :demo, :boolean
    field :end_at, :string
    field :instructor_user_id, :integer
    field :mechanic_user_id, :integer
    field :note, :string
    field :payer_name, :string
    field :start_at, :string
    field :inst_start_at, :naive_datetime
    field :inst_end_at, :naive_datetime
    field :type, :string
    field :user_id, :integer
    field :room_id, :integer
    field :simulator_id, :integer
    field :recurrence, :recurrence_input
  end

  input_object :recurrence_input do
    field :type, non_null(:repeat_type)
    field :days, list_of(non_null(:integer))
    field :end_at, non_null(:naive_datetime)
  end

  input_object :edit_appointment_input do
    field :id, :integer
    field :aircraft_id, :integer
    field :demo, :boolean
    field :end_at, :string
    field :instructor_user_id, :integer
    field :mechanic_user_id, :integer
    field :note, :string
    field :payer_name, :string
    field :start_at, :string
    field :inst_start_at, :naive_datetime
    field :inst_end_at, :naive_datetime
    field :user_id, :integer
    field :room_id, :integer
    field :simulator_id, :integer
  end

  input_object :appointment_filters do
    field :instructor_user_id, :integer
    field :mechanic_user_id, :integer
    field :owner_user_id, :integer
    field :user_id, :integer
    field :aircraft_id, :integer
    field :archived, :boolean
    field :school_id, :integer
    field :room_id, :integer
    field :demo, :boolean
    field :assigned, :boolean
    field :upcoming, :boolean
    field :past, :boolean
    field :from, :naive_datetime
    field :to, :naive_datetime
    field :type, :string
    field :status, :string
    field :search_criteria, :appointment_search_criteria
    field :search_term, :string
  end

  input_object :unavailability_filters do
    field :instructor_user_id, :integer
    field :aircraft_id, :integer

    field :from, :naive_datetime
    field :to, :naive_datetime
    field :start_at_after, :naive_datetime
    field :assigned, :boolean
  end
end
