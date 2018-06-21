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

defmodule FlightWeb.API.DetailedTransactionForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Flight.Billing
  alias Flight.Billing.{Transaction, TransactionLineItem, AircraftLineItemDetail}

  alias FlightWeb.API.DetailedTransactionForm.{AircraftDetails, InstructorDetails}

  @primary_key false
  embedded_schema do
    field(:user_id, :integer)
    field(:source, :string)
    field(:creator_user_id, :integer)
    field(:appointment_id, :integer)
    field(:expected_total, :integer)
    embeds_one(:aircraft_details, AircraftDetails)
    embeds_one(:instructor_details, InstructorDetails)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:user_id, :creator_user_id, :appointment_id, :expected_total, :source])
    |> cast_embed(:aircraft_details, required: false)
    |> cast_embed(:instructor_details, required: false)
    |> validate_required([:user_id, :creator_user_id])
    |> validate_either_aircraft_or_instructor()
    |> validate_appointment()
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

  def validate_appointment(changeset) do
    if changeset.valid? do
      appointment_id = get_field(changeset, :appointment_id)
      # TODO: Check that payment hasn't already been made for appointment
      changeset
    else
      changeset
    end
  end

  def to_transaction(form) do
    {aircraft_line_item, aircraft_details} =
      if form.aircraft_details do
        aircraft_details = form.aircraft_details
        aircraft = Flight.Scheduling.get_aircraft(aircraft_details.aircraft_id)

        detail = %AircraftLineItemDetail{
          hobbs_start: aircraft_details.hobbs_start,
          hobbs_end: aircraft_details.hobbs_end,
          tach_start: aircraft_details.tach_start,
          tach_end: aircraft_details.tach_end
        }

        line_item = %TransactionLineItem{
          amount:
            Billing.aircraft_cost!(
              aircraft,
              aircraft_details.hobbs_start,
              aircraft_details.hobbs_end,
              0.1
            ),
          aircraft_id: aircraft.id
        }

        {line_item, detail}
      else
        {nil, nil}
      end

    instructor_line_item =
      if form.instructor_details do
        instructor = Flight.Accounts.get_user(form.instructor_details.instructor_id)

        %TransactionLineItem{
          amount:
            Flight.Billing.instructor_cost!(instructor, form.instructor_details.hour_tenths),
          instructor_user_id: instructor.id
        }
      end

    line_items = Enum.filter([aircraft_line_item, instructor_line_item], & &1)

    total =
      line_items
      |> Enum.map(& &1.amount)
      |> Enum.reduce(0, &Kernel.+/2)

    transaction = %Transaction{
      total: total,
      state: "pending",
      type: "debit",
      user_id: form.user_id,
      creator_user_id: form.creator_user_id
    }

    {transaction, instructor_line_item, aircraft_line_item, aircraft_details}
  end
end
