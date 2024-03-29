defmodule Flight.Billing.PaymentError do
  defstruct message: ""

  def to_message(error) do
    if is_atom(error) do
      to_string(error)
    else
      error.message
    end
  end
end

defmodule Flight.Billing.PayTransaction do
  import Ecto.Changeset
  require Logger

  alias Flight.{Repo, Billing.Transaction}
  alias FlightWeb.ViewHelpers
  alias Flight.Billing.PaymentError

  def run(transaction) do
    #Logger.info fn -> "run**************************************************************************: #{inspect transaction }" end

    transaction = Repo.preload(transaction, [:user, :invoice])

    case transaction.payment_option do
      :balance -> update_user_balance(transaction)
      :cc -> create_charge(transaction)
      _ -> complete_transaction(transaction)
    end
  end

  def pay_demo_invoice_cc_transaction(invoice_id, user_id) do
    filter =
      if user_id != nil do
        [invoice_id: invoice_id, user_id: user_id]

      else
        [invoice_id: invoice_id]
      end


    with %{id: _id} = trans <- Repo.get_by(Transaction, filter) do
      complete_transaction(trans)
      
    else
      nil -> {:error, "Transaction not found."}
    end
  end

  def pay_invoice_cc_transaction(invoice_id, session_id) do
    _attribs = %{
      "stripe_charge_id" => session_id
    }

    with %{id: _id} = trans <- Repo.get_by(Transaction, invoice_id: invoice_id) do
      complete_transaction(trans)
      
    else
      nil -> {:error, "Transaction not found."}
    end
  end

  defp update_user_balance(transaction) do
    user = transaction.user
    changeset = change(user, balance: user.balance - transaction.total)

    case Repo.update(changeset) do
      {:ok, _} ->
        complete_transaction(transaction)

      {:error, changeset} ->
        error_message = ViewHelpers.human_error_messages(changeset) |> Enum.join(", ")
        fail_transaction(transaction, error_message)
        {:error, changeset}
    end
  end

  defp create_charge(transaction) do
    user = transaction.user
    #Logger.info fn -> "create_charge**************************************************************************: #{inspect transaction }" end

    try do
      case Stripe.Customer.retrieve(user.stripe_customer_id) do
        {:ok, customer} ->
          charge_result =
            Flight.Billing.create_stripe_charge(customer.default_source, transaction)

          case charge_result do
            {:ok, charge} ->
              complete_transaction(transaction, %{stripe_charge_id: charge.id})

            {:error, raw_error} ->
              error = %PaymentError{message: PaymentError.to_message(raw_error)}
              fail_transaction(transaction, error.message)
              {:error, error}
          end

        {:error, error} ->
          fail_transaction(transaction, error.message)
          {:error, error}
      end
    rescue
      error in RuntimeError ->
        fail_transaction(transaction, error.message)
        {:error, error}
    end
  end

  defp complete_transaction(transaction, attrs \\ %{}) do
    paid_by_column = Transaction.get_paid_by_column(transaction)

    transaction_attrs =
      %{
        state: "completed",
        completed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
      |> Map.merge(attrs)
      |> Map.merge(%{paid_by_column => transaction.total})

    change(transaction, transaction_attrs) |> Repo.update()
  end

  defp fail_transaction(transaction, error_message) do
    changes = %{
      state: "failed",
      error_message: error_message,
      completed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }

    change(transaction, changes) |> Repo.update()
  end
end
