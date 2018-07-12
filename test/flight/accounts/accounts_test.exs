defmodule Flight.Accounts.AccountsTest do
  use Flight.DataCase
  use Bamboo.Test, shared: true

  alias Flight.Accounts
  alias Flight.Accounts.{Invitation, User}

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

    @tag :integration
    test "create_user/1 with valid data creates a user" do
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
                 school_fixture()
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

    test "get_user_by_email is case insensitive" do
      user = user_fixture(%{email: "foo@example.com"})
      assert Accounts.get_user_by_email("FoO@EXampLE.com", user)
    end

    test "admin_update_user_profile/2 update roles" do
      user = user_fixture() |> assign_role("admin")
      role_fixture(%{slug: "student"})
      assert {:ok, user} = Accounts.admin_update_user_profile(user, %{}, ["student"], [])

      role =
        assoc(user, :roles)
        |> Repo.all()
        |> List.first()

      assert role.slug == "student"
    end

    test "admin_update_user_profile/2 update flyer certificates" do
      user = user_fixture() |> assign_role("admin")
      flyer_certificate_fixture(%{slug: "cfi"})
      assert {:ok, user} = Accounts.admin_update_user_profile(user, %{}, ["admin"], ["cfi"])

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
                 []
               )

      assert user.phone_number == "801-707-1847"
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      refute Accounts.get_user(user.id, user)
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
      assert {:ok, %Accounts.Invitation{} = invitation} =
               Accounts.create_invitation(
                 %{
                   first_name: "foo",
                   last_name: "bar",
                   email: "foo@bar.com",
                   role_id: Accounts.Role.admin().id
                 },
                 school_fixture()
               )

      assert invitation.first_name == "foo"
      assert invitation.last_name == "bar"
      assert invitation.email == "foo@bar.com"
      assert is_binary(invitation.token)
      assert invitation.role_id == Accounts.Role.admin().id

      assert_delivered_email(Flight.Email.invitation_email(invitation))
    end

    test "create_invitation/1 downcases email" do
      assert {:ok, %Accounts.Invitation{} = invitation} =
               Accounts.create_invitation(
                 %{
                   first_name: "foo",
                   last_name: "bar",
                   email: "FOO@bar.com",
                   role_id: Accounts.Role.admin().id
                 },
                 school_fixture()
               )

      assert invitation.email == "foo@bar.com"
    end

    test "create_invitation/1 fails if user already exists with email" do
      user = user_fixture(%{email: "foo@bar.com"})

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

      assert errors_on(changeset).email |> List.first() =~ "already exists"
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
    test "create_user_from_invitation/3 creates user" do
      invitation = invitation_fixture()

      {:ok, user} =
        Accounts.create_user_from_invitation(
          %{
            first_name: "Alex",
            last_name: "Jones",
            phone_number: "801-555-5555",
            email: "foo@bar.com",
            password: "foobargo"
          },
          invitation
        )

      user = Repo.preload(user, :roles)

      assert Enum.find(user.roles, &(&1.id == invitation.role.id))
      assert user.school_id == invitation.school.id
    end
  end
end
