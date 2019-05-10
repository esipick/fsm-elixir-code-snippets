defmodule FlightWeb.API.DetailedTransactionForm.AircraftDetails do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:aircraft_id, :integer)
    field(:hobbs_start, :integer)
    field(:hobbs_end, :integer)
    field(:tach_start, :integer)
    field(:tach_end, :integer)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:aircraft_id, :hobbs_start, :hobbs_end, :tach_start, :tach_end])
    |> validate_required([:aircraft_id, :hobbs_start, :hobbs_end, :tach_start, :tach_end])
    |> validate_hobbs_duration()
    |> validate_tach_duration()
  end

  def validate_hobbs_duration(changeset) do
    if changeset.valid? do
      if get_field(changeset, :hobbs_end) <= get_field(changeset, :hobbs_start) do
        add_error(changeset, :hobbs_end, "cannot be less than or equal to hobbs_start")
      else
        changeset
      end
    else
      changeset
    end
  end

  def validate_tach_duration(changeset) do
    if changeset.valid? do
      if get_field(changeset, :tach_end) <= get_field(changeset, :tach_start) do
        add_error(changeset, :tach_end, "cannot be less than or equal to hobbs_start")
      else
        changeset
      end
    else
      changeset
    end
  end
end

defmodule FlightWeb.API.DetailedTransactionForm.InstructorDetails do
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

defmodule FlightWeb.API.TransactionForm.CustomUser do
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

defmodule FlightWeb.API.TransactionFormHelpers do
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

  def validate_custom_user_and_source_or_cash(changeset) do
    if get_field(changeset, :custom_user) && !get_field(changeset, :source) &&
         !get_field(changeset, :paid_by_cash) do
      add_error(
        changeset,
        :source,
        "must be provided when using a custom user if paid_by_cash not used"
      )

      add_error(
        changeset,
        :paid_by_cash,
        "must be provided when using a custom user if source not used"
      )
    else
      changeset
    end
  end
end

defmodule FlightWeb.API.DetailedTransactionForm do
  use Ecto.Schema

  import Ecto.Changeset
  import FlightWeb.API.TransactionFormHelpers

  alias Flight.Billing

  alias Flight.Billing.{
    Transaction,
    TransactionLineItem,
    AircraftLineItemDetail,
    InstructorLineItemDetail
  }

  alias FlightWeb.API.TransactionForm.{CustomUser}
  alias FlightWeb.API.DetailedTransactionForm.{AircraftDetails, InstructorDetails}

  @primary_key false
  embedded_schema do
    field(:user_id, :integer)
    field(:source, :string)
    field(:creator_user_id, :integer)
    field(:appointment_id, :integer)
    field(:paid_by_cash, :integer)
    embeds_one(:aircraft_details, AircraftDetails)
    embeds_one(:instructor_details, InstructorDetails)
    embeds_one(:custom_user, CustomUser)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:user_id, :creator_user_id, :appointment_id, :source, :paid_by_cash])
    |> cast_embed(:aircraft_details, required: false)
    |> cast_embed(:instructor_details, required: false)
    |> cast_embed(:custom_user, required: false)
    |> validate_required([:creator_user_id])
    |> validate_either_aircraft_or_instructor()
    |> validate_either_user_id_or_custom_user()
    |> validate_custom_user_and_source_or_cash()
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
    {aircraft_line_item, aircraft_details} =
      if form.aircraft_details do
        aircraft_details = form.aircraft_details
        aircraft = Flight.Scheduling.get_aircraft(aircraft_details.aircraft_id, school_context)

        if !aircraft do
          raise "Unknown aircraft (#{form.aircraft_details.aircraft_id}) for school (#{
                  Flight.SchoolScope.school_id(school_context)
                })"
        end

        rate =
          case rate_type do
            :normal -> aircraft.rate_per_hour
            :block -> aircraft.block_rate_per_hour
          end

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

        line_item = %TransactionLineItem{
          amount: Billing.aircraft_cost!(detail),
          type: "aircraft",
          aircraft_id: aircraft.id
        }

        {line_item, detail}
      else
        {nil, nil}
      end

    {instructor_line_item, instructor_details} =
      if form.instructor_details do
        instructor =
          Flight.Accounts.get_user(form.instructor_details.instructor_id, school_context)

        if !instructor do
          raise "Unknown instructor (#{form.instructor_details.instructor_id}) for school (#{
                  Flight.SchoolScope.school_id(school_context)
                })"
        end

        detail = %InstructorLineItemDetail{
          instructor_user_id: form.instructor_details.instructor_id,
          billing_rate: instructor.billing_rate,
          pay_rate: instructor.pay_rate,
          hour_tenths: form.instructor_details.hour_tenths
        }

        line_item = %TransactionLineItem{
          amount: Flight.Billing.instructor_cost!(detail),
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

    if form.user_id do
      user = Flight.Accounts.get_user(form.user_id, school_context)

      if !user do
        raise "Unknown user (#{form.user_id}) for school (#{
                Flight.SchoolScope.school_id(school_context)
              })"
      end
    end

    transaction =
      %Transaction{
        total: total,
        state: "pending",
        type: "debit",
        user_id: form.user_id,
        creator_user_id: form.creator_user_id,
        school_id: Flight.SchoolScope.school_id(school_context)
      }
      |> Pipe.pass_unless(form.custom_user, fn transaction ->
        %{
          transaction
          | first_name: form.custom_user.first_name,
            last_name: form.custom_user.last_name,
            email: form.custom_user.email
        }
      end)
      |> Pipe.pass_unless(form.paid_by_cash, fn transaction ->
        %{transaction | paid_by_cash: form.paid_by_cash}
      end)

    {transaction, instructor_line_item, instructor_details, aircraft_line_item, aircraft_details}
  end
end
