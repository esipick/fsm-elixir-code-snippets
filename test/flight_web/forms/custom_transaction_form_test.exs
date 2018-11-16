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

  test "error if no user_id or custom_user" do
    attrs = %{
      creator_user_id: 9,
      description: "hi",
      amount: 5000
    }

    changeset = CustomTransactionForm.changeset(%CustomTransactionForm{}, attrs)

    assert errors_on(changeset).user

    refute changeset.valid?
  end

  test "error if both user_id and custom_user" do
    attrs = %{
      user_id: 3,
      creator_user_id: 9,
      description: "hi",
      amount: 5000,
      custom_user: %{
        first_name: "Foo",
        last_name: "Bar",
        email: "foo@bar.com"
      }
    }

    changeset = CustomTransactionForm.changeset(%CustomTransactionForm{}, attrs)

    assert errors_on(changeset).user

    refute changeset.valid?
  end
end
