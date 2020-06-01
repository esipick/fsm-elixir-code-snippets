defmodule Flight.Billing.BulkInvoice do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Flight.Repo
  alias Flight.Accounts.{User, School}
  alias Flight.Billing.{Transaction, Invoice}

  @required_fields ~w(
    payment_option
    total_amount_due
    school_id
    user_id
  )a

  schema "bulk_invoices" do
    field(:payment_option, InvoicePaymentOptionEnum)
    field(:total_amount_due, :integer)
    field(:status, InvoiceStatusEnum, default: :pending)

    belongs_to(:user, User)
    belongs_to(:school, School)
    has_many(:bulk_invoices, Invoice, on_delete: :nilify_all)
    has_one(:bulk_transaction, Transaction, on_delete: :nilify_all)

    timestamps()
  end

  def create(attrs) do
    BulkInvoice.changeset(%BulkInvoice{}, attrs) |> Repo.insert()
  end

  @doc false
  def changeset(%BulkInvoice{} = bulk_invoice, attrs) do
    bulk_invoice
    |> cast(attrs, @required_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:school)
    |> validate_required(@required_fields)
    |> validate_number(:total_amount_due, greater_than: 0)
  end

  def paid(%BulkInvoice{} = bulk_invoice) do
    change(bulk_invoice, status: :paid) |> Repo.update()
  end

  def paid_by_cc(%BulkInvoice{} = bulk_invoice) do
    attrs = [payment_option: :cc, status: :paid]
    change(bulk_invoice, attrs) |> Repo.update()
  end
end
