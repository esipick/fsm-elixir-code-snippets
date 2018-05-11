defmodule Flight.AccountsFixtures do
  alias Flight.{Accounts, Repo, Scheduling}

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "user-#{Flight.Random.string(10)}@email.com",
        first_name: "some first name",
        last_name: "some last name",
        password: "some password"
      })
      |> Accounts.create_user()

    user
  end

  def role_fixture(attrs \\ %{}) do
    role =
      %Accounts.Role{
        slug: Flight.Random.hex(20)
      }
      |> Accounts.Role.changeset(attrs)
      |> Repo.insert!()

    role
  end

  def flyer_certificate_fixture(attrs \\ %{}) do
    cert =
      %Accounts.FlyerCertificate{
        slug: "cfi"
      }
      |> Accounts.FlyerCertificate.changeset(attrs)
      |> Repo.insert!()

    cert
  end

  def invitation_fixture(attrs \\ %{}, role \\ role_fixture()) do
    invitation =
      %Accounts.Invitation{
        first_name: "Jess",
        last_name: "Hamilton",
        email: "#{Flight.Random.hex(20)}-user@email.com",
        role_id: role.id
      }
      |> Accounts.Invitation.create_changeset(attrs)
      |> Repo.insert!()

    %{invitation | role: role}
  end

  # def flyer_details_fixture(attrs \\ %{}, user \\ user_fixture()) do
  #   {:ok, flyer_details} =
  #     attrs
  #     |> Enum.into(%{
  #       address_1: "1234 Hi",
  #       city: "Bigfork",
  #       state: "MT",
  #       faa_tracking_number: "ABC1234"
  #     })
  #     |> Accounts.set_flyer_details_for_user(user)
  #
  #   %{flyer_details | user: user}
  # end

  def assign_role(user, role) do
    assign_roles(user, [role])
  end

  def assign_roles(user, role_slugs) do
    for slug <- role_slugs do
      role =
        (Repo.get_by(Accounts.Role, slug: slug) || %Accounts.Role{slug: slug})
        |> Accounts.Role.changeset(%{})
        |> Repo.insert_or_update!()

      (Repo.get_by(Accounts.UserRole, user_id: user.id, role_id: role.id) ||
         %Accounts.UserRole{user_id: user.id, role_id: role.id})
      |> Accounts.UserRole.changeset(%{})
      |> Repo.insert_or_update!()
    end

    user
  end
end
