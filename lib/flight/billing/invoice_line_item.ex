defmodule Flight.Billing.InvoiceLineItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Flight.Billing.InvoiceLineItem

  @required_fields ~w(description rate amount quantity)a

  schema "invoice_line_items" do
    field(:rate, :integer)
    field(:amount, :integer)
    field(:quantity, :float)
    field(:description, :string)
    field(:type, InvoiceLineItemTypeEnum, default: :other)

    belongs_to(:instructor_user, Flight.Accounts.User)
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
  def changeset(%InvoiceLineItem{} = invoice_line_item, attrs) do
    invoice_line_item
    |> cast(attrs, @required_fields)
    |> cast(attrs, [:instructor_user_id, :aircraft_id, :type])
    |> validate_required(@required_fields)
    |> validate_inclusion(:rate, -999_999..999_999, message: "must be less than 10,000")
    |> validate_number(:quantity, greater_than: 0, less_than: 1000)
    |> validate_conditional_required(:aircraft_id, &aircraft_type?(&1))
    |> validate_conditional_required(:instructor_user_id, &instructor_type?(&1))
  end

  def validate_conditional_required(changeset, field, conditional) do
    if conditional.(changeset) do
      validate_required(changeset, field)
    else
      changeset
    end
  end
end
