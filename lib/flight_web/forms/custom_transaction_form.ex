defmodule FlightWeb.API.CustomTransactionForm do
  use Ecto.Schema

  import Ecto.Changeset
  import FlightWeb.API.TransactionFormHelpers

  alias Flight.Billing.{Transaction, TransactionLineItem}
  alias FlightWeb.API.TransactionForm.{CustomUser}

  @primary_key false
  embedded_schema do
    field(:user_id, :integer)
    field(:creator_user_id, :integer)
    field(:description, :string)
    field(:amount, :integer)
    field(:source, :string)
    embeds_one(:custom_user, CustomUser)
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:user_id, :creator_user_id, :description, :amount, :source])
    |> cast_embed(:custom_user, required: false)
    |> validate_required([:creator_user_id, :description, :amount])
    |> validate_number(:amount, greater_than_or_equal_to: 100, message: "must be more than $1.00")
    |> validate_length(:description, min: 1, max: 5000, message: "must be present")
    |> validate_either_user_id_or_custom_user()
    |> validate_custom_user_and_source_or_cash()
  end

  def to_transaction(form, school_context) do
    line_item = %TransactionLineItem{
      amount: form.amount,
      type: "custom",
      description: form.description
    }

    user_id =
      if form.user_id do
        Flight.Accounts.get_user(form.user_id, school_context).id
      end

    creator_user = Flight.Accounts.get_user(form.creator_user_id, school_context)

    transaction =
      %Transaction{
        total: line_item.amount,
        state: "pending",
        type: "debit",
        user_id: user_id,
        creator_user_id: creator_user.id,
        school_id: Flight.SchoolScope.school_id(school_context)
      }
      |> Pipe.pass_unless(form.custom_user, fn transaction ->
        %{
          transaction
          | first_name: form.custom_user.first_name,
            last_name: form.custom_user.last_name,
            email: form.custom_user.email
        }
      end)

    {transaction, line_item}
  end
end
