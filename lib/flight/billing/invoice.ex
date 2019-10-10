defmodule Flight.Billing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  alias Flight.{Repo, Billing.Invoice}

  @required_fields ~w(
    user_id
    payment_option
    user_balance
    date
    total
    tax_rate
    total_tax
    total_amount_due
  )a

  schema "invoices" do
    field(:date, :date)
    field(:total, :float)
    field(:tax_rate, :float)
    field(:total_tax, :float)
    field(:total_amount_due, :float)
    field(:user_balance, :integer, default: 0)
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