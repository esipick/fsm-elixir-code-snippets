defmodule Flight.Accounts.StripeAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stripe_accounts" do
    field(:stripe_account_id, :string)
    field(:details_submitted, :boolean)
    field(:charges_enabled, :boolean)
    field(:payouts_enabled, :boolean)
    belongs_to(:school, Flight.Accounts.School)

    timestamps()
  end

  @doc false
  def changeset(stripe_account, attrs) do
    stripe_account
    |> cast(attrs, [
      :stripe_account_id,
      :details_submitted,
      :charges_enabled,
      :payouts_enabled,
      :school_id
    ])
    |> validate_required([
      :stripe_account_id,
      :details_submitted,
      :charges_enabled,
      :payouts_enabled,
      :school_id
    ])
  end

  def new(%Stripe.Account{} = account) do
    update(%Flight.Accounts.StripeAccount{}, account)
  end

  def update(%__MODULE__{} = struct, %Stripe.Account{} = account) do
    %__MODULE__{
      struct
      | stripe_account_id: account.id,
        details_submitted: account.details_submitted,
        charges_enabled: account.charges_enabled,
        payouts_enabled: account.payouts_enabled
    }
  end

  def status(stripe_account) do
    cond do
      !stripe_account ->
        :disconnected

      stripe_account.charges_enabled && stripe_account.payouts_enabled &&
          stripe_account.details_submitted ->
        :running

      true ->
        :error
    end
  end
end
