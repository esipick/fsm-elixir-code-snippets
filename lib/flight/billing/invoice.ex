defmodule Flight.Billing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Flight.{Repo, Accounts.User}
  alias Flight.Billing.{Transaction, InvoiceLineItem}
  alias FlightWeb.API.{UserView, InvoiceLineItemView}

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

    belongs_to(:user, User)
    has_many(:line_items, InvoiceLineItem, on_replace: :delete)
    has_many(:transactions, Transaction)

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

  def paid(%Invoice{} = invoice) do
    change(invoice, status: :paid) |> Repo.update
  end

  def get_edit_props(%Invoice{} = invoice) do
    invoice = Repo.preload(invoice, [:user, :line_items])
    user = UserView.render("skinny_user.json", user: invoice.user)

    line_items =
      invoice.line_items
      |> Enum.map(fn line_item ->
        InvoiceLineItemView.render("line_item.json", line_item: line_item)
      end)

    Map.take(invoice, @required_fields)
    |> Map.merge(%{id: invoice.id, action: "edit", student: user, line_items: line_items})
  end
end
