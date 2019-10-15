defmodule Flight.Billing.CreateInvoice do
  import Ecto.Changeset

  alias Flight.Repo
  alias Flight.Billing.{Invoice, Transaction}

  def run(invoice_params, school_context) do
    result = Repo.transaction(fn ->
      case Invoice.create(invoice_params) do
        {:ok, invoice} ->
          case pay(invoice, school_context) do
            {:ok, %Invoice{} = invoice} -> invoice
            {:error, %Ecto.Changeset{} = changeset} -> Repo.rollback(changeset)
            {:error, %Stripe.Error{} = error} -> Repo.rollback(error)
          end
        {:error, error} -> Repo.rollback(error)
      end
    end)

    result
  end

  def pay(invoice, school_context) do
    invoice = Repo.preload(invoice, :user)

    case invoice.payment_option do
      :balance -> pay_off_balance(invoice, school_context)
      :cc -> create_charge(invoice, school_context)
      _ -> {:ok, invoice}
    end
  end

  defp pay_off_balance(invoice, school_context) do
    remainder = invoice.user.balance - invoice.total_amount_due

    if remainder >= 0 do
      update_user_balance(invoice, remainder, school_context)
    else
      case update_user_balance(invoice, 0, school_context) do
        {:ok, invoice} -> create_charge(invoice, school_context, abs(remainder))
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  defp create_charge(invoice, school_context, amount \\ nil) do
    user = invoice.user
    amount = amount || invoice.total_amount_due

    case create_transaction(invoice, school_context, %{type: "credit", total: amount}) do
      {:ok, transaction} ->
        charge_result =
          Stripe.Charge.create(%{
            amount: amount,
            currency: "usd",
            customer: user.stripe_customer_id,
            description: "One-Time Subscription",
            receipt_email: user.email
          })

        case charge_result do
          {:ok, charge} ->
            complete_transaction(
              transaction,
              %{stripe_charge_id: charge.id, paid_by_charge: amount}
            )

            {:ok, invoice}

          {:error, error} -> {:error, error}
        end

      {:error, changeset} -> {:error, changeset}
    end
  end

  defp update_user_balance(invoice, new_balance, school_context) do
    user = invoice.user
    total = user.balance - new_balance
    changeset = change(user, balance: new_balance)

    case create_transaction(invoice, school_context, %{total: total}) do
      {:ok, transaction} ->
        case Repo.update(changeset) do
          {:ok, user} ->
            complete_transaction(transaction, %{paid_by_balance: total})
            {:ok, invoice}

          {:error, changeset} -> {:error, changeset}
        end

      {:error, changeset} -> {:error, changeset}
    end
  end

  defp create_transaction(invoice, school_context, attrs \\ %{}) do
    user = invoice.user

    changeset =
      %Transaction{
        state: "pending",
        type: "debit",
        user_id: user.id,
        invoice_id: invoice.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        creator_user_id: school_context.assigns.current_user.id,
        school_id: Flight.SchoolScope.school_id(school_context)
      }
      |> Transaction.changeset(attrs)
      |> Repo.insert
  end

  defp complete_transaction(transaction, attrs \\ %{}) do
    change(
      transaction,
      %{state: "completed", completed_at: NaiveDateTime.utc_now()} |> Map.merge(attrs)
    )
    |> Repo.update
  end
end
