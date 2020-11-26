defmodule Fsm.Billing.DetailedTransactionForm.AircraftDetails do
    use Ecto.Schema
    import Ecto.Changeset
    import MapUtil
    import HobbsTachUtil
  
    alias Flight.Repo
    alias Fsm.Scheduling.Aircraft
  
    @primary_key false
    embedded_schema do
      field(:aircraft_id, :integer)
      field(:hobbs_start, :integer)
      field(:hobbs_end, :integer)
      field(:tach_start, :integer)
      field(:tach_end, :integer)
      field(:ignore_last_time, :boolean, virtual: true, default: false)
    end
  
    def changeset(struct, raw_attrs) do
      attrs = atomize_shallow(raw_attrs) |> coerce_hobbs_tach_time()
  
      struct
      |> cast(attrs, [
        :aircraft_id,
        :hobbs_start,
        :hobbs_end,
        :tach_start,
        :tach_end,
        :ignore_last_time
      ])
      |> validate_required([:aircraft_id, :hobbs_start, :hobbs_end, :tach_start, :tach_end])
      |> validate_hobbs_duration()
      |> validate_tach_duration()
    end
  
    def validate_hobbs_duration(changeset) do
      if changeset.valid? do
        hobbs_start = get_field(changeset, :hobbs_start)
  
        if get_field(changeset, :hobbs_end) <= hobbs_start do
          add_error(changeset, :hobbs_end, "must be greater than hobbs start")
        else
          aircraft = Repo.get(Aircraft, get_field(changeset, :aircraft_id))
  
          if !get_field(changeset, :ignore_last_time) && aircraft.last_hobbs_time > hobbs_start do
            message =
              "must be greater than current aircraft hobbs start (#{aircraft.last_hobbs_time / 10.0})"
  
            add_error(changeset, :hobbs_start, message)
          else
            changeset
          end
        end
      else
        changeset
      end
    end
  
    def validate_tach_duration(changeset) do
      if changeset.valid? do
        tach_start = get_field(changeset, :tach_start)
  
        if get_field(changeset, :tach_end) <= tach_start do
          add_error(changeset, :tach_end, "must be greater than tach start")
        else
          aircraft = Repo.get(Aircraft, get_field(changeset, :aircraft_id))
  
          if !get_field(changeset, :ignore_last_time) && aircraft.last_tach_time > tach_start do
            message =
              "must be greater than current aircraft tach start (#{aircraft.last_tach_time / 10.0})"
  
            add_error(changeset, :tach_start, message)
          else
            changeset
          end
        end
      else
        changeset
      end
    end
  end
  
  defmodule Fsm.Billing.DetailedTransactionForm.InstructorDetails do
    use Ecto.Schema
    import Ecto.Changeset
  
    @primary_key false
    embedded_schema do
      field(:instructor_id, :integer)
      field(:hour_tenths, :integer)
    end
  
    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:instructor_id, :hour_tenths])
      |> validate_required([:instructor_id, :hour_tenths])
      |> validate_hour_tenths()
    end
  
    def validate_hour_tenths(changeset) do
      if changeset.valid? do
        if get_field(changeset, :hour_tenths) <= 0 do
          add_error(changeset, :hour_tenths, "cannot be less than or equal to zero")
        else
          changeset
        end
      else
        changeset
      end
    end
  end
  
  defmodule Fsm.Billing.TransactionForm.CustomUser do
    use Ecto.Schema
    import Ecto.Changeset
  
    @primary_key false
    embedded_schema do
      field(:first_name, :string)
      field(:last_name, :string)
      field(:email, :string)
    end
  
    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:first_name, :last_name, :email])
      |> validate_required([:first_name, :last_name, :email])
    end
  end
  
  defmodule Fsm.Billing.TransactionFormHelpers do
    import Ecto.Changeset
  
    def validate_either_user_id_or_custom_user(changeset) do
      if (changeset.valid? &&
            (!get_field(changeset, :user_id) && !get_field(changeset, :custom_user))) ||
           (get_field(changeset, :user_id) && get_field(changeset, :custom_user)) do
        add_error(
          changeset,
          :user,
          "or custom card should be sent, but not both."
        )
      else
        changeset
      end
    end
  
    def validate_custom_user_and_source(changeset) do
      if get_field(changeset, :custom_user) && !get_field(changeset, :source) do
        add_error(
          changeset,
          :source,
          "must be provided when using a custom user"
        )
      else
        changeset
      end
    end
  end
  
  defmodule Fsm.Billing.DetailedTransactionForm do
    use Ecto.Schema
  
    import Ecto.Changeset
    import Fsm.Billing.TransactionFormHelpers
  
  
    alias Fsm.Billing.{
      Transaction,
      TransactionLineItem,
      AircraftLineItemDetail,
      InstructorLineItemDetail
    }
  
    alias Fsm.Billing.TransactionForm.{CustomUser}
    alias Fsm.Billing.DetailedTransactionForm.{AircraftDetails, InstructorDetails}
  
    @primary_key false
    embedded_schema do
      field(:user_id, :integer)
      field(:source, :string)
      field(:creator_user_id, :integer)
      field(:appointment_id, :integer)
      embeds_one(:aircraft_details, AircraftDetails)
      embeds_one(:instructor_details, InstructorDetails)
      embeds_one(:custom_user, CustomUser)
    end
  
    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:user_id, :creator_user_id, :appointment_id, :source])
      |> cast_embed(:aircraft_details, required: false)
      |> cast_embed(:instructor_details, required: false)
      |> cast_embed(:custom_user, required: false)
      |> validate_required([:creator_user_id])
      |> validate_either_aircraft_or_instructor()
      |> validate_either_user_id_or_custom_user()
      |> validate_custom_user_and_source()
    end
  
    def validate_either_aircraft_or_instructor(changeset) do
      if !get_field(changeset, :aircraft_details) && !get_field(changeset, :instructor_details) do
        add_error(
          changeset,
          :aircraft_details,
          "Either aircraft_details or instructor_details must be set."
        )
      else
        changeset
      end
    end
  
    def to_transaction(form, rate_type, school_context)
        when rate_type in [:normal, :block] do
      # user = Repo.preload(user, [:school])
      # sales_tax = user && user.school.sales_tax
      # sales_tax = sales_tax || 0
      tax_rate = Map.get(form, :tax_rate) || 0
  
      {aircraft_line_item, aircraft_details} =
        if Map.get(form, :aircraft_details) do
          aircraft_details = form.aircraft_details
  
          aircraft =
            Fsm.Scheduling.get_aircraft(aircraft_details.aircraft_id, school_context)
  
          if !aircraft do
            raise "Unknown aircraft (#{form.aircraft_details.aircraft_id}) for school (#{
                    Fsm.SchoolScope.school_id(school_context)
                  })"
          end
  
          rate =
            case rate_type do
              :normal -> aircraft.rate_per_hour
              :block -> aircraft.block_rate_per_hour
            end
  
          custom_rate = Map.get(form.aircraft_details, :rate_per_hour)
          rate =
            if custom_rate, do: custom_rate, else: rate 
            #13 6 2 6
            # of flights time flow
  
          detail = %AircraftLineItemDetail{
            aircraft_id: aircraft_details.aircraft_id,
            hobbs_start: aircraft_details.hobbs_start,
            hobbs_end: aircraft_details.hobbs_end,
            tach_start: aircraft_details.tach_start,
            tach_end: aircraft_details.tach_end,
            fee_percentage: 0.00,
            rate_type: Atom.to_string(rate_type),
            rate: rate
          }
  
          amount = Billing.aircraft_cost!(detail)
          total_tax = 
            if Map.get(aircraft_details, :taxable), do: round(amount * tax_rate / 100), else: 0
          
          # calculate amount and save.
          line_item = %TransactionLineItem{
            amount: amount,
            total_tax: total_tax,
            type: "aircraft",
            aircraft_id: aircraft.id
          }
  
          {line_item, detail}
        else
          {nil, nil}
        end
  
      {instructor_line_item, instructor_details} =
        if Map.get(form, :instructor_details) do
          instructor =
            Fsm.Accounts.get_user_regardless(form.instructor_details.instructor_id, school_context)
  
          if !instructor do
            raise "Unknown instructor (#{form.instructor_details.instructor_id}) for school (#{
                    Fsm.SchoolScope.school_id(school_context)
                  })"
          end
  
          billing_rate = Map.get(form.instructor_details, :billing_rate) || instructor.billing_rate
  
          detail = %InstructorLineItemDetail{
            instructor_user_id: form.instructor_details.instructor_id,
            billing_rate: billing_rate,
            pay_rate: instructor.pay_rate,
            hour_tenths: form.instructor_details.hour_tenths
          }
  
          amount = Fsm.Billing.instructor_cost!(detail)
          total_tax = 
            if Map.get(form.instructor_details, :taxable), do: round(amount * tax_rate / 100), else: 0
  
          line_item = %TransactionLineItem{
            amount: amount,
            total_tax: total_tax,
            type: "instructor",
            instructor_user_id: instructor.id
          }
  
          {line_item, detail}
        else
          {nil, nil}
        end
  
      line_items = Enum.filter([aircraft_line_item, instructor_line_item], & &1)
  
      total =
        line_items
        |> Enum.map(& &1.amount)
        |> Enum.reduce(0, &Kernel.+/2)
  
      user_id = Map.get(form, :user_id)
  
      if user_id do
        user = Fsm.Accounts.get_user(form.user_id, school_context)
  
        if !user do
          raise "Unknown user (#{form.user_id}) for school (#{
                  Fsm.SchoolScope.school_id(school_context)
                })"
        end
      end
  
      transaction =
        %Transaction{
          total: total,
          state: "pending",
          type: "debit",
          user_id: user_id,
          creator_user_id: Map.get(form, :creator_user_id),
          school_id: Fsm.SchoolScope.school_id(school_context)
        }
        |> Pipe.pass_unless(Map.get(form, :custom_user), fn transaction ->
          %{
            transaction
            | first_name: form.custom_user.first_name,
              last_name: form.custom_user.last_name,
              email: form.custom_user.email
          }
        end)
  
      {transaction, instructor_line_item, instructor_details, aircraft_line_item, aircraft_details}
    end
  end
  