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
        attrs = %{
          user_id: user.id,
          total: amount,
          state: "completed",
          type: "credit"
        }

        case create_transaction(school_context, attrs) do
          {:ok, transaction} -> {:ok, invoice}
          {:error, changeset} -> {:error, changeset}
        end

      {:error, error} -> {:error, error}
    end
  end

  defp update_user_balance(invoice, new_balance, school_context) do
    user = invoice.user
    total = user.balance - new_balance
    changeset = change(user, balance: new_balance)

    case Repo.update(changeset) do
      {:ok, user} ->
        attrs = %{
          user_id: user.id,
          total: total,
          state: "completed"
        }

        case create_transaction(school_context, attrs) do
          {:ok, transaction} -> {:ok, invoice}
          {:error, changeset} -> {:error, changeset}
        end

      {:error, changeset} -> {:error, changeset}
    end
  end

  defp create_transaction(school_context, attrs \\ %{}) do
    changeset =
      %Transaction{
        state: "pending",
        type: "debit",
        creator_user_id: school_context.assigns.current_user.id,
        school_id: Flight.SchoolScope.school_id(school_context)
      }
      |> Transaction.changeset(attrs)
      |> Repo.insert
  end
end
