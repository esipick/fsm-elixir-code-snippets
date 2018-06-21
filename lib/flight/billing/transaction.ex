defmodule Flight.Billing.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field(:paid_by_balance, :integer)
    field(:paid_by_charge, :integer)
    field(:state, :string)
    field(:stripe_charge_id, :string)
    field(:total, :integer)
    field(:type, :string)
    field(:completed_at, :naive_datetime)
    belongs_to(:user, Flight.Accounts.User)
    belongs_to(:creator_user, Flight.Accounts.User)
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
      :stripe_charge_id,
      :type,
      :state,
      :completed_at,
      :user_id,
      :creator_user_id
    ])
    |> cast_assoc(:line_items)
    |> validate_required([
      :total,
      :state,
      :type,
      :user_id,
      :creator_user_id
    ])
    |> validate_inclusion(:state, ["pending", "completed", "canceled"])
    |> validate_inclusion(:type, ["debit", "credit"])
  end
end
