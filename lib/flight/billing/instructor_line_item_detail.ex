defmodule Flight.Billing.InstructorLineItemDetail do
  use Ecto.Schema
  import Ecto.Changeset

  schema "instructor_line_item_details" do
    field(:billing_rate, :integer)
    field(:hour_tenths, :integer)
    field(:pay_rate, :integer)
    belongs_to(:transaction_line_item, Flight.Billing.TransactionLineItem)
    belongs_to(:instructor_user, Flight.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(instructor_line_item_detail, attrs) do
    instructor_line_item_detail
    |> cast(attrs, [
      :hour_tenths,
      :billing_rate,
      :pay_rate,
      :transaction_line_item_id,
      :instructor_user_id
    ])
    |> validate_required([
      :hour_tenths,
      :billing_rate,
      :pay_rate,
      :transaction_line_item_id,
      :instructor_user_id
    ])
  end
end
