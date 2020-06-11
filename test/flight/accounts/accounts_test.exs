defmodule Flight.Accounts.AccountsTest do
  use Flight.DataCase
  use Bamboo.Test, shared: true

  alias Flight.Accounts
  alias Flight.Accounts.{SchoolInvitation, Invitation, User}

  describe "users" do
    @valid_attrs %{
      email: "some email",
      first_name: "some first name",
      last_name: "some last name",
      password: "some password"
    }
    @invalid_attrs %{balance: nil, email: nil, name: nil, password: nil}

    test "get_user/2 returns user with roles" do
      user = user_fixture() |> assign_role("admin")
      user_id = user.id
      assert %User{id: ^user_id} = Accounts.get_user(user.id, ["admin"], user)
    end

    test "get_user/2 does not return user without roles" do
      user = user_fixture() |> assign_role("student")
      refute Accounts.get_user(user.id, ["admin"], user)
    end

    test "get_user_count/2 ignores archived users" do
      school = school_fixture()
      role = Accounts.Role.student()
      user = student_fixture(%{}, school)
      student_fixture(%{}, school)

      assert Accounts.get_user_count(role, school)

      Accounts.archive_user(user)
      assert Accounts.get_user_count(role, school)
    end

    @tag :integration
    test "create_user/1 with valid data creates a user" do
      school = school_fixture() |> real_stripe_account()

      assert {:ok, %User{} = user} =
               Accounts.create_user(
                 %{
                   # Space here is intentional, should be trimmed
                   email: "foo@bar.com ",
                   first_name: "Tammy",
                   last_name: "Jones",
                   phone_number: "801-555-5555",
                   password: "password"
                 },
                 school
               )

      assert user.balance == 0
      assert user.email == "foo@bar.com"
      assert user.first_name == "Tammy"
      assert user.last_name == "Jones"
      assert user.stripe_customer_id
      assert {:ok, _} = Accounts.check_password(user, "password")
    end

    test "create_user/1 fails with no password" do
      assert {:error, changeset} =
               Accounts.create_user(Enum.into(%{password: ""}, @valid_attrs), school_fixture())

      assert errors_on(changeset).password
    end

    test "check_password fails for invalid password" do
      assert user = user_fixture(%{password: "hello_world"})
      assert {:error, _user} = Accounts.check_password(user, "hello_w0rld")
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs, school_fixture())
    end

    test "get_user_by_email/2 is case insensitive" do
      user_fixture(%{email: "foo@example.com"})
      assert Accounts.get_user_by_email("FoO@EXampLE.com")
    end

    test "get_user_by_email/2 for email empty email" do
      user_fixture(%{email: "foo@example.com"})
      refute Accounts.get_user_by_email("")
    end

    test "get_user_by_email/2 for email is nil" do
      user_fixture(%{email: "foo@example.com"})
      refute Accounts.get_user_by_email(nil)
    end

    test "get_user_by_email for email empty email" do
      refute Accounts.get_user_by_email("")
    end

    test "get_user_by_email for email is nil" do
      refute Accounts.get_user_by_email(nil)
    end

    test "admin_update_user_profile/2 update roles" do
      user = user_fixture() |> assign_role("admin")
      role_fixture(%{slug: "student"})

      assert {:ok, user} = Accounts.admin_update_user_profile(user, %{}, ["student"], [], [], [])

      role =
        assoc(user, :roles)
        |> Repo.all()
        |> List.first()

      assert role.slug == "student"
    end

    test "admin_update_user_profile/2 update flyer certificates" do
      user = user_fixture() |> assign_role("admin")
      flyer_certificate_fixture(%{slug: "cfi"})

      assert {:ok, user} =
               Accounts.admin_update_user_profile(user, %{}, ["admin"], [], ["cfi"], [])

      cert =
        assoc(user, :flyer_certificates)
        |> Repo.all()
        |> List.first()

      assert cert.slug == "cfi"
    end

    test "admin_update_user_profile/2 updates date" do
      user = user_fixture() |> assign_role("admin")
      role_fixture(%{slug: "student"})

      assert {:ok, user} =
               Accounts.admin_update_user_profile(
                 user,
                 %{"medical_expires_at" => "3/3/2018"},
                 [
                   "student"
                 ],
                 [],
                 [],
                 []
               )

      assert user.medical_expires_at == ~D[2018-03-03]
    end

    test "admin_update_user_profile/2 normalizes phone_number" do
      user = user_fixture() |> assign_role("admin")
      role_fixture(%{slug: "student"})

      assert {:ok, user} =
               Accounts.admin_update_user_profile(
                 user,
                 %{"phone_number" => "(801) 707-1847"},
                 [
                   "student"
                 ],
                 [],
                 [],
                 []
               )

      assert user.phone_number == "801-707-1847"
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.archive_user(user)
      refute Accounts.get_user(user.id, user)
    end

    test "delete_user/1 resets password token" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.archive_user(user)
      refute user.password_token == Repo.get(User, user.id).password_token
    end

    test "set_password/2 sets password for user" do
      user = user_fixture()

      assert {:error, _} = Accounts.check_password(user, "blarghy blargh")

      {:ok, user} = Accounts.set_password(user, "blarghy blargh")

      assert {:ok, _user} = Accounts.check_password(user, "blarghy blargh")
    end
  end

  describe "roles" do
    test "assign_role/2 assigns role to user" do
      user = user_fixture()

      assert [%Accounts.UserRole{user_id: user_id}] =
               Accounts.assign_roles(user, [Accounts.Role.admin()])

      assert user_id == user.id

      assert Repo.one(assoc(user, :roles)).slug == "admin"
    end

    test "has_role?/2 true if has role" do
      user = user_fixture() |> assign_role("admin")
      assert Accounts.has_role?(user, "admin")
    end

    test "has_role?/2 false if doesn't have role" do
      user = user_fixture()
      refute Accounts.has_role?(user, "admin")
    end

    test "has_any_role?/2 true if has all roles" do
      user = user_fixture() |> assign_roles(["admin", "renter"])
      assert Accounts.has_any_role?(user, ["admin", "student"])
    end

    test "has_any_role?/2 false if doesn't have role" do
      user = user_fixture() |> assign_roles(["instructor", "student"])
      refute Accounts.has_any_role?(user, ["admin", "renter"])
    end
  end

  describe "flyer_certificates" do
    test "has_flyer_certificate?/2 true if has role" do
      user = user_fixture()
      cert = flyer_certificate_fixture(%{slug: "cfi"})

      Repo.insert!(%Accounts.UserFlyerCertificate{user_id: user.id, flyer_certificate_id: cert.id})

      assert Accounts.has_flyer_certificate?(user, "cfi")
    end

    test "has_role?/2 false if doesn't have role" do
      user = user_fixture()
      flyer_certificate_fixture(%{slug: "cfi"})
      refute Accounts.has_flyer_certificate?(user, "cfi")
    end
  end

  describe "invitations" do
    test "create_invitation/1 creates invitation" do
      stripe_account = stripe_account_fixture()

      assert {:ok, %Accounts.Invitation{} = invitation} =
               Accounts.create_invitation(
                 %{
                   first_name: "foo",
                   last_name: "bar",
                   email: "foo@bar.com",
                   role_id: Accounts.Role.admin().id
                 },
                 stripe_account.school
               )

      assert invitation.first_name == "foo"
      assert invitation.last_name == "bar"
      assert invitation.email == "foo@bar.com"
      assert is_binary(invitation.token)
      assert invitation.role_id == Accounts.Role.admin().id

      assert_delivered_email(Flight.Email.invitation_email(invitation))
    end

    test "create_invitation/1 downcases email" do
      stripe_account = stripe_account_fixture()

      assert {:ok, %Accounts.Invitation{} = invitation} =
               Accounts.create_invitation(
                 %{
                   first_name: "foo",
                   last_name: "bar",
                   email: "FOO@bar.com",
                   role_id: Accounts.Role.admin().id
                 },
                 stripe_account.school
               )

      assert invitation.email == "foo@bar.com"
    end

    test "create_invitation/1 fails if user already exists with email" do
      stripe_account = stripe_account_fixture()

      user = user_fixture(%{email: "foo@bar.com"}, stripe_account.school)

      assert {:error, changeset} =
               Accounts.create_invitation(
                 %{
                   first_name: "foo",
                   last_name: "bar",
                   email: "foo@bar.com",
                   role_id: Accounts.Role.admin().id
                 },
                 user
               )

      assert errors_on(changeset).user |> List.first() =~ "has already signed up."
    end

    test "accept_invitation/1 accepts if not accepted" do
      invitation = invitation_fixture()
      assert is_nil(invitation.accepted_at)

      assert {:ok, %Accounts.Invitation{accepted_at: %NaiveDateTime{}}} =
               Accounts.accept_invitation(invitation)
    end

    test "accept_invitation/1 fails if already accepted" do
      invitation = invitation_fixture()
      {:ok, invitation} = Accounts.accept_invitation(invitation)
      assert {:error, :already_accepted} = Accounts.accept_invitation(invitation)
    end

    test "delete_invitation!/1 removes invitation" do
      invitation = invitation_fixture()

      assert {:ok, %Invitation{}} = Accounts.delete_invitation!(invitation)
    end

    test "send_invitation_email/1 sends email" do
      invitation = invitation_fixture(%{}, Flight.Accounts.Role.admin())
      Accounts.send_invitation_email(invitation)
      assert_delivered_email(Flight.Email.invitation_email(invitation))
    end

    test "get_invitation/2 returns invitation" do
      invitation = invitation_fixture()
      assert invitation.id == Accounts.get_invitation(invitation.id, invitation.school).id
    end

    test "get_invitation/2 scopes to school" do
      invitation = invitation_fixture()
      refute Accounts.get_invitation(invitation.id, school_fixture())
    end

    test "get_invitation_for_token/2 returns invitation" do
      invitation = invitation_fixture()

      assert invitation.token

      assert invitation.id ==
               Accounts.get_invitation_for_token(invitation.token, invitation.school).id
    end

    test "get_invitation_for_token/2 scopes to school" do
      invitation = invitation_fixture()
      refute Accounts.get_invitation_for_token(invitation.token, school_fixture())
    end

    test "get_invitation_for_email/2 returns invitation" do
      invitation = invitation_fixture(%{email: "micky@rooney.com"})

      assert invitation.id ==
               Accounts.get_invitation_for_email("micky@rooney.com", invitation.school).id
    end

    test "get_invitation_for_email/2 scopes to school" do
      invitation_fixture(%{email: "micky@rooney.com"})
      refute Accounts.get_invitation_for_email("micky@rooney.com", school_fixture())
    end

    test "visible_invitations_with_role/2 returns unaccepted invitations" do
      school = school_fixture()
      invitation = invitation_fixture(%{}, Flight.Accounts.Role.admin(), school)

      # Shouldn't return because different role
      _ = invitation_fixture(%{}, Flight.Accounts.Role.student(), school)

      # Shouldn't return because different school
      _ = invitation_fixture(%{}, Flight.Accounts.Role.admin(), school_fixture())

      # Shouldn't return because already accepted
      _ =
        invitation_fixture(
          %{},
          Flight.Accounts.Role.admin(),
          school
        )
        |> Invitation.accept_changeset(%{accepted_at: ~N[2018-03-03 10:00:00]})
        |> Repo.update!()

      assert Enum.map(Accounts.visible_invitations_with_role("admin", school), & &1.id) == [
               invitation.id
             ]
    end

    @tag :integration
    test "create_user_from_invitation/3 for student creates Stripe customer with card, and charges it" do
      school = school_fixture() |> real_stripe_account()

      invitation = invitation_fixture(%{}, Flight.Accounts.Role.student(), school)

      assert {:ok, _user} =
               Accounts.create_user_from_invitation(
                 %{
                   first_name: "Alex",
                   last_name: "Jones",
                   phone_number: "801-555-5555",
                   email: "foo@bar.com",
                   password: "foobargo"
                 },
                 "tok_visa",
                 invitation
               )
    end

    @tag :integration
    test "create_user_from_invitation/3 for renter creates Stripe customer with card, but does not charge it" do
      school = school_fixture() |> real_stripe_account()

      invitation = invitation_fixture(%{}, Flight.Accounts.Role.renter(), school)

      assert {:ok, _user} =
               Accounts.create_user_from_invitation(
                 %{
                   first_name: "Alex",
                   last_name: "Jones",
                   phone_number: "801-555-5555",
                   email: "foo@bar.com",
                   password: "foobargo"
                 },
                 "tok_visa",
                 invitation
               )
    end
  end

  describe "schools" do
    @tag :integration
    test "create_school/2 creates school with stripe account" do
      email = "#{Flight.Random.hex(52)}@mailinator.com"

      assert {:ok, school} =
               Accounts.create_school(%{
                 name: "Dave's Flight School",
                 contact_first_name: "Hal",
                 contact_last_name: "Leonard",
                 contact_phone_number: "555-555-5555",
                 timezone: "America/Denver",
                 contact_email: email
               })

      assert school.name == "Dave's Flight School"
      assert school.contact_first_name == "Hal"
      assert school.contact_last_name == "Leonard"
      assert school.contact_email == email
      assert school.contact_phone_number == "555-555-5555"

      assert stripe_account =
               Flight.Repo.get_by(Flight.Accounts.StripeAccount, school_id: school.id)

      assert stripe_account.stripe_account_id
      assert stripe_account.charges_enabled
      refute stripe_account.payouts_enabled
      refute stripe_account.details_submitted
    end

    test "create_school/2 creates school without stripe account" do
      assert {:ok, school} =
               Accounts.create_school(%{
                 name: "Dave's Flight School",
                 contact_email: "parkerwightman@gmail.com",
                 contact_first_name: "Hal",
                 contact_last_name: "Leonard",
                 timezone: "America/Denver",
                 contact_phone_number: "555-555-5555"
               })

      refute Flight.Repo.get_by(Flight.Accounts.StripeAccount, school_id: school.id)
    end

    test "create_school_invitation/1 creates invitation and sends email" do
      assert {:ok, %SchoolInvitation{} = invitation} =
               Accounts.create_school_invitation(%{
                 email: "foo@bar.com",
                 first_name: "Alice",
                 last_name: "Potter"
               })

      assert invitation.email == "foo@bar.com"
      assert is_binary(invitation.token)

      assert_delivered_email(Flight.Email.school_invitation_email(invitation))
    end

    test "delete_school_invitation!/1 removes school_invitation" do
      school_invitation = school_invitation_fixture()

      assert {:ok, %SchoolInvitation{}} = Accounts.delete_school_invitation!(school_invitation)
    end

    @tag :integration
    test "create_school_from_invitation/2 creates school and admin" do
      school_invitation = school_invitation_fixture()

      refute school_invitation.accepted_at

      email = "#{Flight.Random.hex(33)}@bar.com"

      data = %{
        school_name: "School name",
        first_name: "Jesse",
        last_name: "Allen",
        phone_number: "801-555-5555",
        timezone: "America/Denver",
        email: email,
        password: "hello world"
      }

      assert {:ok, {school, _user}} =
               Accounts.create_school_from_invitation(data, school_invitation)

      school = school |> Repo.preload(:school_onboarding)
      school_onboarding = school.school_onboarding

      assert school.name == "School name"
      assert school.contact_first_name == "Jesse"
      assert school.contact_last_name == "Allen"
      assert school.contact_phone_number == "801-555-5555"
      assert school.contact_email == email

      assert school_onboarding.current_step == :school
      assert school_onboarding.completed == false

      assert refresh(school_invitation).accepted_at

      user =
        Repo.get_by!(User, school_id: school.id)
        |> Repo.preload([:roles])

      assert List.first(user.roles).id == Flight.Accounts.Role.admin().id

      assert user.first_name == school.contact_first_name
      assert user.last_name == school.contact_last_name
      assert user.email == school.contact_email
      assert user.phone_number == school.contact_phone_number
      assert user.stripe_customer_id

      assert {:ok, _} = Accounts.check_password(user, "hello world")
    end

    @tag :integration
    test "fetch_and_create_stripe_account_from_account_id/2 creates stripe account and create stripe ids for all users that don't have one" do
      {:ok, api_account} =
        Flight.Billing.create_deferred_stripe_account(
          "#{Flight.Random.hex(32)}@mailinator.com",
          "Sunny Skies"
        )

      school = school_fixture()
      admin = admin_fixture(%{stripe_customer_id: nil}, school)

      refute admin.stripe_customer_id

      {:ok, _account} =
        Accounts.fetch_and_create_stripe_account_from_account_id(api_account.id, school)

      assert refresh(admin).stripe_customer_id
    end

    @tag :integration
    test "create_school_from_invitation/2 creates school and admin, without stripe account or customer id" do
      school_invitation = school_invitation_fixture()

      refute school_invitation.accepted_at

      email = "parkerwightman@gmail.com"

      data = %{
        school_name: "School name",
        first_name: "Jesse",
        last_name: "Allen",
        phone_number: "801-555-5555",
        email: email,
        timezone: "America/Denver",
        password: "hello world"
      }

      assert {:ok, {school, _user}} =
               Accounts.create_school_from_invitation(data, school_invitation)

      assert school.name == "School name"
      assert school.contact_first_name == "Jesse"
      assert school.contact_last_name == "Allen"
      assert school.contact_phone_number == "801-555-5555"
      assert school.contact_email == email

      assert refresh(school_invitation).accepted_at

      user =
        Repo.get_by!(User, school_id: school.id)
        |> Repo.preload([:roles])

      assert List.first(user.roles).id == Flight.Accounts.Role.admin().id

      refute user.stripe_customer_id
      assert user.first_name == school.contact_first_name
      assert user.last_name == school.contact_last_name
      assert user.email == school.contact_email
      assert user.phone_number == school.contact_phone_number

      assert {:ok, _} = Accounts.check_password(user, "hello world")
    end
  end
end
