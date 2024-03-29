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
    field(:payment_option, InvoicePaymentOptionEnum, default: :balance)
    field(:payer_name, :string)
    field(:demo, :boolean, default: false)
    field(:archived, :boolean, default: false)
    field(:is_visible, :boolean, default: false)
    field(:archived_at, :naive_datetime)
    field(:appointment_updated_at, :naive_datetime)
    field(:notes, :string)
    field(:payer_email, :string, default: nil)

    field(:aircraft_info, :map, null: true)
    field(:session_id, :string, null: true)
    field(:course_id, :integer, null: true)
    field(:is_admin_invoice, :boolean, default: false)

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
    |> cast(attrs, [:aircraft_info, :appointment_id, :archived, :is_visible, :status, :appointment_updated_at, :demo, :session_id, :course_id, :is_admin_invoice, :notes, :payer_email])
    |> cast_assoc(:line_items)
    |> assoc_constraint(:user)
    |> assoc_constraint(:school)
    |> validate_required(@required_fields)
    |> validate_required_inclusion(@payer_fields)
    |> validate_appointment_is_valid
    # |> validate_payment_option
#    |> validate_number(:total_amount_due, greater_than: 0)
    |> validate_number(:total_tax, greater_than_or_equal_to: 0)
#    |> validate_number(:total, greater_than: 0)
  end

  def payment_options_changeset(%Invoice{} = invoice, attrs) do
    invoice
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_payment_option
  end

  def paid(%Invoice{} = invoice) do
    change(invoice, status: :paid) |> Repo.update()
  end

  def paid_by_cc(nil), do: {:error, nil}
  def paid_by_cc(%Invoice{} = invoice) do
    attrs = [payment_option: :cc, status: :paid]
    change(invoice, attrs) |> Repo.update()
  end

  def save_invoice(%Invoice{} = invoice, attrs) do
    invoice
    |> changeset(attrs)
    |> Repo.update
  end

  def get_by_session_id(nil), do: nil
  def get_by_session_id(session_id) do
    Repo.get_by(Invoice, [session_id: session_id])
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

  def validate_payment_option(%Ecto.Changeset{valid?: true} = changeset) do
    user_id = get_change(changeset, :user_id) || get_field(changeset, :user_id)
    payment_option = get_change(changeset, :payment_option) || get_field(changeset, :payment_option)

    IO.inspect(changeset, label: "Changeset")

    if user_id == nil and payment_option in [nil, :balance] do
      add_error(changeset, :payment_option, "A valid payment option is required.")
    else
      changeset
    end
  end
  def validate_payment_option(changeset), do: changeset

  def archive(%Flight.Billing.Invoice{} = invoice) do
    if !invoice.archived do
      archived_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

      change(invoice, %{archived: true, archived_at: archived_at})
      |> Flight.Repo.update()
    end
  end
end
