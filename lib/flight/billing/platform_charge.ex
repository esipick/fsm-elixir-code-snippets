defmodule Flight.Billing.PlatformCharge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "platform_charges" do
    field(:amount, :integer)
    field(:stripe_charge_id, :string)
    field(:type, :string)
    belongs_to(:user, Flight.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(platform_charge, attrs) do
    platform_charge
    |> cast(attrs, [:amount, :type, :stripe_charge_id, :user_id])
    |> validate_required([:amount, :type, :stripe_charge_id, :user_id])
    |> validate_inclusion(:type, ["platform_fee"])
  end
end
