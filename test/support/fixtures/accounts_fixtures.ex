defmodule Flight.AccountsFixtures do
  alias Flight.{Accounts, Repo}
  alias Flight.Accounts.{User}

  def user_fixture(attrs \\ %{}) do
    user =
      %User{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "some first name",
        last_name: "some last name",
        phone_number: "801-555-5555",
        stripe_customer_id: "cus_#{Flight.Random.hex(20)}"
      }
      |> User.__test_changeset(%{password: "some password"} |> Map.merge(attrs))
      |> Repo.insert!()

    %{user | password: nil}
  end

  def student_fixture(attrs \\ %{}) do
    user_fixture(attrs) |> assign_role("student")
  end

  def instructor_fixture(attrs \\ %{}) do
    user_fixture(attrs) |> assign_role("instructor")
  end

  def admin_fixture(attrs \\ %{}) do
    user_fixture(attrs) |> assign_role("admin")
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
    roles =
      for slug <- role_slugs do
        role =
          (Repo.get_by(Accounts.Role, slug: slug) || %Accounts.Role{slug: slug})
          |> Accounts.Role.changeset(%{})
          |> Repo.insert_or_update!()

        (Repo.get_by(Accounts.UserRole, user_id: user.id, role_id: role.id) ||
           %Accounts.UserRole{user_id: user.id, role_id: role.id})
        |> Accounts.UserRole.changeset(%{})
        |> Repo.insert_or_update!()

        role
      end

    %{user | roles: roles}
  end
end
