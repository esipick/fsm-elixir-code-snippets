defmodule Flight.Billing.TransactionLineItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transaction_line_items" do
    field(:amount, :integer)
    field(:description, :string)
    belongs_to(:transaction, Flight.Billing.Transaction)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)
    belongs_to(:instructor_user, Flight.Accounts.User)
    has_one(:aircraft_detail, Flight.Billing.AircraftLineItemDetail)

    timestamps()
  end

  @doc false
  def changeset(transaction_line_item, attrs) do
    transaction_line_item
    |> cast(attrs, [:amount, :description, :transaction_id, :aircraft_id, :instructor_user_id])
    |> validate_required([:amount, :transaction_id])
  end
end
