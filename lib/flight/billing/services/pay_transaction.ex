defmodule Flight.Billing.PayTransaction do
  import Ecto.Changeset

  alias Flight.Repo
  alias Flight.Billing.{Invoice, Transaction}

  def run(transaction) do
    transaction = Repo.preload(transaction, [:user, :invoice])

    if transaction.type == "credit" do
      create_charge(transaction)
    else
      update_user_balance(transaction)
    end
  end

  defp update_user_balance(transaction) do
    user = transaction.user
    changeset = change(user, balance: user.balance - transaction.total)

    case Repo.update(changeset) do
      {:ok, user} -> complete_transaction(transaction)
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp create_charge(transaction) do
    user = transaction.user

    charge_result =
      Stripe.Charge.create(%{
        amount: transaction.total,
        currency: "usd",
        customer: user.stripe_customer_id,
        description: "One-Time Subscription",
        receipt_email: user.email
      })

    case charge_result do
      {:ok, charge} -> complete_transaction(transaction, %{stripe_charge_id: charge.id})
      {:error, error} -> {:error, error}
    end
  end

  defp complete_transaction(transaction, attrs \\ %{}) do
    change(
      transaction,
      %{state: "completed", completed_at: NaiveDateTime.utc_now()} |> Map.merge(attrs)
    )
    |> Repo.update
  end
end
