defmodule Flight.Billing.InvoiceLineItem do
  use Ecto.Schema
  import Ecto.Changeset
  alias Flight.Repo
  alias Flight.Scheduling.{Aircraft}
  alias Flight.Accounts.User
  import MapUtil
  import HobbsTachUtil

  alias Flight.Billing.InvoiceLineItem
  alias Flight.SchoolAssets.Room

  @required_fields ~w(description rate amount quantity)a
  @hobbs_tach_fields ~w(hobbs_start hobbs_end tach_start tach_end hobbs_tach_used)a
  @maintenance_fields ~w(part_number part_cost)a

  schema "invoice_line_items" do
    field(:rate, :integer)
    field(:amount, :integer)
    field(:quantity, :float)
    field(:description, :string)
    field(:hobbs_start, :integer)
    field(:hobbs_end, :integer)
    field(:tach_start, :integer)
    field(:tach_end, :integer)
    field(:hobbs_tach_used, :boolean)
    field(:taxable, :boolean)
    field(:deductible, :boolean)
    field(:type, InvoiceLineItemTypeEnum, default: :other)
    field(:course_id, :integer, null: true)
    field(:part_number, :string)
    field(:part_cost, :integer)
    belongs_to(:room, Room)
    belongs_to(:creator, User)
    belongs_to(:instructor_user, User)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)
    belongs_to(:invoice, Flight.Billing.Invoice)

    timestamps()
  end

  InvoiceLineItemTypeEnum.__enum_map__()
  |> Enum.map(fn {k, _v} ->
    def unquote(:"#{k}_type?")(changeset) do
      get_field(changeset, :type) == unquote(k)
    end
  end)

  @doc false
  def changeset(%InvoiceLineItem{} = invoice_line_item, raw_attrs) do
    rate = Map.get(raw_attrs, "rate") || 0
    raw_attrs = Map.put(raw_attrs, "rate", round(rate))

    attrs = atomize_shallow(raw_attrs) |> coerce_hobbs_tach_time()

    invoice_line_item
    |> cast(attrs, @required_fields)
    |> cast(attrs, @hobbs_tach_fields)
    |> cast(attrs, @maintenance_fields)
    |> cast(attrs, [:instructor_user_id, :room_id, :creator_id, :aircraft_id, :type, :taxable, :deductible, :course_id])
    |> validate_required(@required_fields)
    |> validate_number(:quantity, greater_than: 0)
    |> validate_conditional_required(:aircraft_id, &aircraft_type?(&1))
    |> validate_conditional_required(:instructor_user_id, &instructor_type?(&1))
    |> validate_conditional_required(:room_id, &room_type?(&1))
    |> validate_aircraft_existence
    |> validate_instructor_existence
    |> validate_room_existence
  end

  def validate_conditional_required(changeset, field, conditional) do
    if conditional.(changeset) do
      validate_required(changeset, field)
    else
      changeset
    end
  end

  def validate_aircraft_existence(changeset) do
    aircraft_id = get_field(changeset, :aircraft_id)

    if aircraft_id do
      aircraft = Repo.get(Aircraft, aircraft_id)

      if aircraft do
        changeset
      else
        add_error(changeset, :aircraft_id, "does not exist")
      end
    else
      changeset
    end
  end

  def validate_instructor_existence(changeset) do
    instructor_user_id = get_field(changeset, :instructor_user_id)

    if instructor_user_id do
      instructor_user = Repo.get(User, instructor_user_id)

      if instructor_user do
        changeset
      else
        add_error(changeset, :instructor_user_id, "does not exist")
      end
    else
      changeset
    end
  end

  def validate_room_existence(changeset) do
    room_id = get_field(changeset, :room_id)

    if room_id do
      room = Repo.get(Room, room_id)

      if room do
        changeset
      else
        add_error(changeset, :room_id, "does not exist")
      end
    else
      changeset
    end
  end
end
