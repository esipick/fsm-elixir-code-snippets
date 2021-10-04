defmodule Flight.AccountsFixtures do
  alias Flight.{Accounts, Repo}
  alias Flight.Accounts.{User, School, StripeAccount, SchoolOnboarding}

  def avatar_base64_fixture(path \\ "assets/static/images/margot.jpg") do
    path
    |> File.read!()
    |> Base.encode64()
  end

  def upload_fixture(path \\ "assets/static/images/margot.jpg") do
    type = MIME.from_path(path)

    %Plug.Upload{content_type: type, filename: Path.basename(path), path: path}
  end

  def school_fixture_without_onboarding(attrs \\ %{}) do
    %School{
      name: "some_school_name",
      contact_email:
        "fsm+#{Timex.now() |> Timex.to_unix()}-#{Flight.Random.hex(4)}@mailinator.com",
      contact_first_name: "Billy",
      contact_last_name: "Jean",
      contact_phone_number: "555-555-5555",
      timezone: "America/Denver",
      sales_tax: 10.0
    }
    |> School.create_changeset(attrs)
    |> Repo.insert!()
  end

  def school_fixture(attrs \\ %{}) do
    school = school_fixture_without_onboarding(attrs)
    school_onboarding = completed_school_onboarding_fixture(school)

    %{school | school_onboarding: school_onboarding}
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

  def school_onboarding_fixture(attrs \\ %{}, school \\ school_fixture_without_onboarding()) do
    attrs = Map.merge(%{school_id: school.id}, attrs)
    {:ok, school_onboarding} = SchoolOnboarding.create(attrs)
    school = %{school | school_onboarding: school_onboarding}

    %{school_onboarding | school: school}
  end

  def completed_school_onboarding_fixture(school \\ school_fixture()) do
    school_onboarding_fixture(%{completed: true, current_step: :resources}, school)
  end

  def default_school_fixture() do
    school = Repo.get_by(School, name: "default")
    school || school_fixture(%{name: "default"})
  end

  def user_fixture(
        attrs \\ %{},
        %School{} = school \\ default_school_fixture(),
        instructors \\ nil,
        aircrafts \\ nil
      ) do
    user =
      %User{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "some first name",
        last_name: "some last name",
        phone_number: "801-555-5555",
        stripe_customer_id: "cus_#{Flight.Random.hex(20)}",
        school_id: school.id,
        billing_rate: 100
      }
      |> User.__test_changeset(
        %{password: "some password"} |> Map.merge(attrs),
        instructors,
        aircrafts
      )
      |> Repo.insert!()

    %{user | password: nil, school: school}
  end

  def student_fixture(
        attrs \\ %{},
        school \\ default_school_fixture(),
        instructors \\ nil,
        aircrafts \\ nil
      ) do
    user_fixture(attrs, school, instructors, aircrafts) |> assign_role("student")
  end

  def instructor_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    user_fixture(attrs, school) |> assign_role("instructor")
  end

  def admin_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    user_fixture(attrs, school) |> assign_role("admin")
  end

  def superadmin_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    user = admin_fixture(attrs, school)
    Application.put_env(:flight, :superadmin_ids, [user.id])
    user
  end

  def dispatcher_fixture(attrs \\ %{}, school \\ default_school_fixture()) do
    user_fixture(attrs, school) |> assign_role("dispatcher")
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
