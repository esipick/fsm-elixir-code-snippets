defmodule Flight.Accounts.AcceptInvitation do
  alias Flight.Repo
  alias Flight.Accounts
  alias Flight.Accounts.User

  def run(user_data, stripe_token, invitation) do
    invitation = Repo.preload(invitation, [:school, :user])
    user = if invitation.user do
      Repo.preload(invitation.user, [:roles, :school, :flyer_certificates])
    else
      %User{}
    end

    Repo.transaction(fn ->
      case Accounts.create_user(user_data, invitation.school, true, stripe_token, user) do
        {:ok, user} ->
          Accounts.accept_invitation(invitation)
          role = Accounts.get_role(invitation.role_id)
          Accounts.assign_roles(user, [role])

          if role.slug == "student" do
            amount = Application.get_env(:flight, :platform_fee_amount)

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
                %Flight.Billing.PlatformCharge{}
                |> Flight.Billing.PlatformCharge.changeset(%{
                  user_id: user.id,
                  amount: amount,
                  type: "platform_fee",
                  stripe_charge_id: charge.id
                })
                |> Repo.insert()

                user

              {:error, error} ->
                Repo.rollback(error)
            end
          else
            user
          end

        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end
end
