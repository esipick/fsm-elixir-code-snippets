defmodule Flight.Accounts.AcceptInvitation do
  alias Flight.Repo
  alias Flight.Accounts
  alias Flight.Accounts.User

  def run(user_data, stripe_token, invitation) do
    invitation = Repo.preload(invitation, [:school, :user])

    user =
      if invitation.user do
        Repo.preload(invitation.user, [
          :roles,
          :school,
          :aircrafts,
          :flyer_certificates,
          :instructors,
          :main_instructor
        ])
      else
        %User{}
      end

    Repo.transaction(fn ->
      case Accounts.create_user(user_data, invitation.school, true, stripe_token, user) do
        {:ok, user} ->
          Accounts.accept_invitation(invitation)
          role = Accounts.get_role(invitation.role_id)
          Accounts.assign_roles(user, [role])

        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end
end
