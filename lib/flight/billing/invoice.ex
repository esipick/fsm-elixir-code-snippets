defmodule Flight.Billing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset
  import ValidationUtil

  alias __MODULE__
  alias Flight.Repo
  alias Flight.Accounts.{User, School}
  alias Flight.Billing.{Transaction, InvoiceLineItem}
  alias Flight.Scheduling.Appointment

  @required_fields ~w(
    payment_option
    date
    total
    tax_rate
    total_tax
    total_amount_due
    school_id
  )a
  @payer_fields ~w(user_id payer_name)a

  schema "invoices" do
    field(:date, :date)
    field(:total, :integer)
    field(:tax_rate, :float)
    field(:total_tax, :integer)
    field(:total_amount_due, :integer)
    field(:status, InvoiceStatusEnum, default: :pending)
    field(:payment_option, InvoicePaymentOptionEnum)
    field(:payer_name, :string)
    field(:archived, :boolean, default: false)
    field(:is_visible, :boolean, default: false)
    field(:archived_at, :naive_datetime)
    field(:appointment_updated_at, :naive_datetime)
    
    field(:aircraft_info, :map, null: true)

    belongs_to(:user, User)
    belongs_to(:school, School)
    belongs_to(:appointment, Appointment)
    belongs_to(:bulk_invoice, Flight.Billing.BulkInvoice)
    has_many(:line_items, InvoiceLineItem, on_replace: :delete, on_delete: :delete_all)
    has_many(:transactions, Transaction, on_delete: :nilify_all)
    has_one(:bulk_transaction, through: [:bulk_invoice, :bulk_transaction])

    timestamps()
  end

  def create(attrs) do
    Invoice.changeset(%Invoice{}, attrs) |> Repo.insert()
  end

  @doc false
  def changeset(%Invoice{} = invoice, attrs) do
    invoice
    |> cast(attrs, @required_fields)
    |> cast(attrs, @payer_fields)
    |> cast(attrs, [:aircraft_info, :appointment_id, :archived, :is_visible, :status, :appointment_updated_at])
    |> cast_assoc(:line_items)
    |> assoc_constraint(:user)
    |> assoc_constraint(:school)
    |> validate_required(@required_fields)
    |> validate_required_inclusion(@payer_fields)
    |> validate_appointment_is_valid
#    |> validate_number(:total_amount_due, greater_than: 0)
    |> validate_number(:total_tax, greater_than_or_equal_to: 0)
#    |> validate_number(:total, greater_than: 0)
  end

  def paid(%Invoice{} = invoice) do
    change(invoice, status: :paid) |> Repo.update()
  end

  def paid_by_cc(%Invoice{} = invoice) do
    attrs = [payment_option: :cc, status: :paid]
    change(invoice, attrs) |> Repo.update()
  end

  def validate_appointment_is_valid(changeset) do
    appointment_id = get_field(changeset, :appointment_id)

    if appointment_id do
      appointment = Repo.get(Appointment, appointment_id) |> Repo.preload(:school)

      if appointment do
        case appointment.archived do
          true ->
            add_error(changeset, :appointment_id, "has already been removed")

          false ->
            changeset
        end
      else
        add_error(changeset, :appointment_id, "does not exist")
      end
    else
      changeset
    end
  end

  def archive(%Flight.Billing.Invoice{} = invoice) do
    if !invoice.archived do
      archived_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

      change(invoice, %{archived: true, archived_at: archived_at})
      |> Flight.Repo.update()
    end
  end
end
