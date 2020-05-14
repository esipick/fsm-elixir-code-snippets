defmodule Flight.Billing.InvoiceLineItem do
  use Ecto.Schema
  import Ecto.Changeset
  alias Flight.Repo
  alias Flight.Scheduling.{Aircraft}
  alias Flight.Accounts.User
  import MapUtil
  import HobbsTachUtil

  alias Flight.Billing.InvoiceLineItem

  @required_fields ~w(description rate amount quantity)a
  @hobbs_tach_fields ~w(hobbs_start hobbs_end tach_start tach_end hobbs_tach_used)a

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
    attrs = symbolize_keys(raw_attrs) |> coerce_hobbs_tach_time()

    invoice_line_item
    |> cast(attrs, @required_fields)
    |> cast(attrs, @hobbs_tach_fields)
    |> cast(attrs, [:instructor_user_id, :aircraft_id, :type, :taxable, :deductible])
    |> validate_required(@required_fields)
    |> validate_number(:rate,
      less_than: 999_999,
      message: "must be less than $10,000"
    )
    |> validate_number(:quantity, greater_than: 0, less_than: 1000)
    |> validate_conditional_required(:aircraft_id, &aircraft_type?(&1))
    |> validate_conditional_required(:instructor_user_id, &instructor_type?(&1))
    |> validate_aircraft_existence
    |> validate_instructor_existence
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
end
