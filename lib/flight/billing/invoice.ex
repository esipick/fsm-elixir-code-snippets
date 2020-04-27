defmodule Flight.Billing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

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
    field(:archived_at, :naive_datetime)

    belongs_to(:user, User)
    belongs_to(:school, School)
    belongs_to(:appointment, Appointment)
    has_many(:line_items, InvoiceLineItem, on_replace: :delete, on_delete: :delete_all)
    has_many(:transactions, Transaction, on_delete: :nilify_all)

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
    |> cast(attrs, [:appointment_id, :archived, :status])
    |> cast_assoc(:line_items)
    |> assoc_constraint(:user)
    |> assoc_constraint(:school)
    |> validate_required(@required_fields)
    |> validate_required_inclusion(@payer_fields)
    |> validate_appointment_existence
  end

  def paid(%Invoice{} = invoice) do
    change(invoice, status: :paid) |> Repo.update()
  end

  def paid_by_cc(%Invoice{} = invoice) do
    attrs = [payment_option: :cc, status: :paid]
    change(invoice, attrs) |> Repo.update()
  end

  def validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      add_error(changeset, hd(fields), "One of these fields must be present: #{inspect(fields)}")
    end
  end

  def validate_appointment_existence(changeset) do
    appointment_id = get_field(changeset, :appointment_id)

    if appointment_id do
      appointment = Repo.get(Appointment, appointment_id)

      if appointment do
        if appointment.archived do
          add_error(changeset, :appointment_id, "has already been removed")
        else
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

  def present?(changeset, field) do
    value = get_field(changeset, field)
    value && value != ""
  end
end
