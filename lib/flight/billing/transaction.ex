defmodule Flight.Billing.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field(:paid_by_balance, :integer)
    field(:paid_by_charge, :integer)
    field(:paid_by_cash, :integer)
    field(:state, :string)
    field(:stripe_charge_id, :string)
    field(:total, :integer)
    field(:type, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:completed_at, :naive_datetime)
    belongs_to(:school, Flight.Accounts.School)
    belongs_to(:user, Flight.Accounts.User)
    belongs_to(:creator_user, Flight.Accounts.User)
    belongs_to(:invoice, Flight.Billing.Invoice)
    has_many(:line_items, Flight.Billing.TransactionLineItem)

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :total,
      :paid_by_balance,
      :paid_by_charge,
      :paid_by_cash,
      :stripe_charge_id,
      :type,
      :state,
      :completed_at,
      :user_id,
      :creator_user_id,
      :first_name,
      :last_name,
      :email
    ])
    |> cast_assoc(:line_items)
    |> validate_required([
      :total,
      :state,
      :type,
      :school_id,
      :creator_user_id
    ])
    |> validate_inclusion(:state, ["pending", "completed", "canceled"])
    |> validate_inclusion(:type, ["debit", "credit"])
  end
end
