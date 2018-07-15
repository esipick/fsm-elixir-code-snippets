defmodule Flight.Accounts.School do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schools" do
    field(:name, :string)
    field(:contact_email, :string)
    has_one(:stripe_account, Flight.Accounts.StripeAccount)

    timestamps()
  end

  @doc false
  def changeset(school, attrs) do
    school
    |> cast(attrs, [:name, :contact_email])
    |> validate_required([:name, :contact_email])
  end
end
