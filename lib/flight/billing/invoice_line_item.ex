defmodule Flight.Billing.InvoiceLineItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Flight.Billing.InvoiceLineItem

  @required_fields ~w(description rate amount quantity)a

  schema "invoice_line_items" do
    field(:description, :string)
    field(:rate, :float)
    field(:amount, :float)
    field(:quantity, :integer)
    belongs_to(:invoice, Flight.Billing.Invoice)

    timestamps()
  end

  @doc false
  def changeset(%InvoiceLineItem{} = invoice_line_item, attrs) do
    invoice_line_item
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
