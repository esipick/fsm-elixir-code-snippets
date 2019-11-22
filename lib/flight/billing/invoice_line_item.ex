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

  @doc false
  def changeset(%InvoiceLineItem{} = invoice_line_item, attrs) do
    invoice_line_item
    |> cast(attrs, @required_fields)
    |> cast(attrs, [:instructor_user_id, :aircraft_id, :type])
    |> validate_required(@required_fields)
  end
end
