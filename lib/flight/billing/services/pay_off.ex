defmodule Flight.Billing.PayOff do
  alias Flight.Billing.{
    PayTransaction
  }
  require Logger
  def balance(nil, _transaction_attrs, _school_context), do: {:error, "Payment method {Balance} not allowed for user."}
  def balance(user, transaction_attrs, school_context) do
    user_balance = user.balance
    total_amount_due = transaction_attrs[:total]
    remainder = user_balance - total_amount_due
    balance_enough = remainder >= 0

    cond do
      (user_balance > 0 && (balance_enough || !!user.stripe_customer_id)) ->
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
          
      !!!user.stripe_customer_id -> {:error, "Payment method not available. Balance is less than the due amount and credit card is not added."}
      true -> {:error, :balance_is_empty}        
    end
  end

  def credit_card(%{stripe_customer_id: nil}, _, _), do: {:error, "Payment method {CC} not available for user. Please update the user profile and add a credit card."}
  def credit_card(user, transaction_attrs, school_context) do
    #Logger.info fn -> "manually122-----------------------: #{inspect transaction_attrs }" end
    case CreateTransaction.run(user, school_context, transaction_attrs) do
      {:ok, transaction} ->
        PayTransaction.run(transaction)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def manually(user, transaction_attrs, school_context) do
    #Logger.info fn -> "manually-----------------------: #{inspect transaction_attrs }" end

    case CreateTransaction.run(user, school_context, transaction_attrs) do
      {:ok, transaction} ->
        PayTransaction.run(transaction)

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
