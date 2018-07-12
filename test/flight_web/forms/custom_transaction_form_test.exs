defmodule FlightWeb.API.CustomTransactionFormTest do
  use Flight.DataCase

  alias FlightWeb.API.CustomTransactionForm
  alias Flight.Billing.{Transaction, TransactionLineItem}

  import Flight.BillingFixtures

  test "valid data" do
    attrs = %{
      user_id: 3,
      creator_user_id: 5,
      amount: 50000,
      description: "Bleh"
    }

    assert %Ecto.Changeset{valid?: true} =
             CustomTransactionForm.changeset(%CustomTransactionForm{}, attrs)
  end

  test "invalid data" do
    attrs = %{
      user_id: 3,
      creator_user_id: 5,
      amount: 0,
      description: ""
    }

    assert %Ecto.Changeset{valid?: false} =
             CustomTransactionForm.changeset(%CustomTransactionForm{}, attrs)
  end

  test "to_transaction/1 creates insertable transaction and line_item" do
    form = custom_transaction_form_fixture()

    {transaction, line_item} =
      CustomTransactionForm.to_transaction(form, default_school_fixture())

    {:ok, transaction} =
      transaction
      |> Transaction.changeset(%{})
      |> Flight.Repo.insert()

    {:ok, _} =
      line_item
      |> TransactionLineItem.changeset(%{transaction_id: transaction.id})
      |> Flight.Repo.insert()
  end
end
