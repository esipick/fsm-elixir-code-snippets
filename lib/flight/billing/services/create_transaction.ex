defmodule CreateTransaction do
  alias Flight.Repo
  alias Flight.Accounts.User
  alias Flight.Billing.Transaction

  def run(user, school_context, attrs) do
    first_name = if user, do: user.first_name, else: attrs[:payer_name]

    transaction =
      %Transaction{
        state: "pending",
        type: "debit",
        user_id: user && user.id,
        email: user && user.email,
        first_name: first_name,
        last_name: user && user.last_name,
        creator_user_id: school_context.assigns.current_user.id,
        school_id: school(school_context).id
      }
      |> Transaction.changeset(attrs)

    transaction =
      with %User{} = user <- user, false <- :ets.insert_new(:locked_users, {user.id}) do
        transaction
        |> Ecto.Changeset.add_error(
          :invoice,
          "Another payment for this user is already in progress."
        )
      else
        _ ->
          transaction
      end

    transaction =
      transaction
      |> Repo.insert()

    if user, do: :ets.delete(:locked_users, user.id)
    transaction
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end
end
