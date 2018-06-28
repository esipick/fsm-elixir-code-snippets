defmodule FlightWeb.API.CustomTransactionForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Flight.Billing.{Transaction, TransactionLineItem}

  @primary_key false
  embedded_schema do
    field(:user_id, :integer)
    field(:creator_user_id, :integer)
    field(:description, :string)
    field(:amount, :integer)
    field(:source, :string)
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:user_id, :creator_user_id, :description, :amount, :source])
    |> validate_required([:user_id, :creator_user_id, :description, :amount])
    |> validate_number(:amount, greater_than_or_equal_to: 100, message: "must be more than $1.00")
    |> validate_length(:description, min: 1, max: 5000, message: "must be present")
  end

  def to_transaction(form) do
    line_item = %TransactionLineItem{
      amount: form.amount,
      description: form.description
    }

    transaction = %Transaction{
      total: line_item.amount,
      state: "pending",
      type: "debit",
      user_id: form.user_id,
      creator_user_id: form.creator_user_id
    }

    {transaction, line_item}
  end
end
