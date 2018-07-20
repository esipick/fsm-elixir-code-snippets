defmodule Flight.AccountsFixtures do
  alias Flight.{Accounts, Repo}
  alias Flight.Accounts.{User, School, StripeAccount}

  def school_fixture(attrs \\ %{}) do
    %School{
      name: "some_school_name",
      contact_email: "fsm+#{Flight.Random.hex(20)}@mailinator.com",
      contact_first_name: "Billy",
      contact_last_name: "Jean",
      contact_phone_number: "555-555-5555"
    }
    |> School.create_changeset(attrs)
    |> Repo.insert!()
  end

  def stripe_account_fixture(attrs \\ %{}, school \\ school_fixture()) do
    account =
      %StripeAccount{
        stripe_account_id: "acc_#{Flight.Random.hex(25)}",
        details_submitted: false,
        charges_enabled: false,
        payouts_enabled: false,
        school_id: school.id
      }
      |> StripeAccount.changeset(attrs)
      |> Repo.insert!()

    %{account | school: school}
  end

  def default_school_fixture() do
    school = Repo.get_by(School, name: "default")
    school || school_fixture(%{name: "default"})
  end

  def user_fixture(attrs \\ %{}, %School{} = school \\ default_school_fixture()) do
    user =
      %User{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "some first name",
        last_name: "some last name",
        phone_number: "801-555-5555",
        stripe_customer_id: "cus_#{Flight.Random.hex(20)}",
        school_id: school.id
      }
      |> User.__test_changeset(%{password: "some password"} |> Map.merge(attrs))
      |> Repo.insert!()

    %{user | password: nil, school: school}
  end

  def student_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    user_fixture(attrs, school) |> assign_role("student")
  end

  def instructor_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    user_fixture(attrs, school) |> assign_role("instructor")
  end

  def admin_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    user_fixture(attrs, school) |> assign_role("admin")
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

  def invitation_fixture(attrs \\ %{}, role \\ role_fixture(), school \\ default_school_fixture()) do
    invitation =
      %Accounts.Invitation{
        first_name: "Jess",
        last_name: "Hamilton",
        email: "#{Flight.Random.hex(20)}-user@email.com",
        role_id: role.id,
        school_id: school.id
      }
      |> Accounts.Invitation.create_changeset(attrs)
      |> Repo.insert!()

    %{invitation | role: role, school: school}
  end

  def school_invitation_fixture(attrs \\ %{}) do
    %Accounts.SchoolInvitation{
      email: "#{Flight.Random.hex(20)}-user@email.com",
      first_name: "Jon",
      last_name: "Lebowski"
    }
    |> Accounts.SchoolInvitation.create_changeset(attrs)
    |> Repo.insert!()
  end

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
