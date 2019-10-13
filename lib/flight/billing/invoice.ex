defmodule Flight.Billing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  alias Flight.{Repo, Billing.Invoice}

  @required_fields ~w(
    user_id
    payment_option
    date
    total
    tax_rate
    total_tax
    total_amount_due
  )a

  schema "invoices" do
    field(:date, :date)
    field(:total, :integer)
    field(:tax_rate, :float)
    field(:total_tax, :integer)
    field(:total_amount_due, :integer)
    field(:status, InvoiceStatusEnum, default: :pending)
    field(:payment_option, InvoicePaymentOptionEnum)

    belongs_to(:user, Flight.Accounts.User)
    has_many(:line_items, Flight.Billing.InvoiceLineItem)

    timestamps()
  end

  def create(attrs) do
    Invoice.changeset(%Invoice{}, attrs) |> Repo.insert()
  end

  @doc false
  def changeset(%Invoice{} = invoice, attrs) do
    invoice
    |> cast(attrs, @required_fields)
    |> cast_assoc(:line_items)
    |> assoc_constraint(:user)
    |> validate_required(@required_fields)
  end
end
