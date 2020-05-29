defmodule Flight.Billing.PayOff do
  alias Flight.Billing.{
    PayTransaction
  }

  def balance(user, transaction_attrs, school_context) do
    user_balance = user.balance
    total_amount_due = transaction_attrs[:total]

    if user_balance > 0 do
      remainder = user_balance - total_amount_due
      balance_enough = remainder >= 0
      total = if balance_enough, do: total_amount_due, else: user_balance

      transaction_attrs =
        transaction_attrs
        |> Map.merge(%{total: total, payment_option: :balance})

      case CreateTransaction.run(user, school_context, transaction_attrs) do
        {:ok, transaction} ->
          case PayTransaction.run(transaction) do
            {:ok, result} ->
              if balance_enough do
                {:ok, :balance_enough, result}
              else
                {:ok, :balance_not_enough, abs(remainder), result}
              end

            {:error, changeset} ->
              {:error, changeset}
          end

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      {:error, :balance_is_empty}
    end
  end

  def credit_card(user, transaction_attrs, school_context) do
    case CreateTransaction.run(user, school_context, transaction_attrs) do
      {:ok, transaction} ->
        PayTransaction.run(transaction)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def manually(user, transaction_attrs, school_context) do
    case CreateTransaction.run(user, school_context, transaction_attrs) do
      {:ok, transaction} ->
        PayTransaction.run(transaction)

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
