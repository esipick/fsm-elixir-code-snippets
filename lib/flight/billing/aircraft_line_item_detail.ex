defmodule Flight.Billing.AircraftLineItemDetail do
  use Ecto.Schema
  import Ecto.Changeset

  schema "aircraft_line_item_details" do
    field(:hobbs_end, :integer)
    field(:hobbs_start, :integer)
    field(:tach_end, :integer)
    field(:tach_start, :integer)
    belongs_to(:transaction_line_item, Flight.Billing.TransactionLineItem)

    timestamps()
  end

  @doc false
  def changeset(aircraft_line_item_detail, attrs) do
    aircraft_line_item_detail
    |> cast(attrs, [:hobbs_start, :hobbs_end, :tach_start, :tach_end, :transaction_line_item_id])
    |> validate_required([
      :hobbs_start,
      :hobbs_end,
      :tach_start,
      :tach_end,
      :transaction_line_item_id
    ])
  end
end