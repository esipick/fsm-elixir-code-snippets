defmodule Flight.Billing.TransactionLineItem do
  use Ecto.Schema
  import Ecto.Changeset
  alias Flight.Billing.InstructorLineItemDetail
  alias Flight.Billing.AircraftLineItemDetail

  schema "transaction_line_items" do
    field(:amount, :integer)
    field(:description, :string)
    field(:type, :string)
    field(:total_tax, :integer, default: 0)
    belongs_to(:transaction, Flight.Billing.Transaction)
    belongs_to(:aircraft, Flight.Scheduling.Aircraft)
    belongs_to(:instructor_user, Flight.Accounts.User)
    has_one(:aircraft_detail, AircraftLineItemDetail)
    has_one(:instructor_detail, InstructorLineItemDetail)

    timestamps()
  end

  @doc false
  def changeset(transaction_line_item, attrs) do
    transaction_line_item
    |> cast(attrs, [
      :amount,
      :type,
      :total_tax,
      :description,
      :transaction_id,
      :aircraft_id,
      :instructor_user_id
    ])
    |> validate_required([:amount, :transaction_id, :type])
    |> validate_inclusion(:type, [
      "aircraft",
      "instructor",
      "sales_tax",
      "custom",
      "add_funds",
      "remove_funds",
      "credit"
    ])
  end
end
