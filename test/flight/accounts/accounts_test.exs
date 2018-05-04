defmodule Flight.Accounts.AccountsTest do
  use Flight.DataCase

  alias Flight.Accounts

  describe "users" do
    alias Flight.Accounts.User

    @valid_attrs %{
      balance: 42,
      email: "some email",
      first_name: "some first name",
      last_name: "some last name",
      password: "some password"
    }
    @update_attrs %{
      balance: 43,
      email: "some updated email",
      first_name: "some updated first name",
      last_name: "some updated last name",
      password: "some updated password"
    }
    @invalid_attrs %{balance: nil, email: nil, name: nil, password: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "get_user/2 returns user with roles" do
      user = user_fixture() |> assign_role("admin")
      user_id = user.id
      assert %User{id: ^user_id} = Accounts.get_user(user.id, ["admin"])
    end

    test "get_user/2 does not return user without roles" do
      user = user_fixture() |> assign_role("student")
      refute Accounts.get_user(user.id, ["admin"])
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} =
               Accounts.create_user(%{
                 balance: 42,
                 email: "foo@bar.com",
                 first_name: "Tammy",
                 last_name: "Jones",
                 password: "password"
               })

      assert user.balance == 42
      assert user.email == "foo@bar.com"
      assert user.first_name == "Tammy"
      assert user.last_name == "Jones"
      assert {:ok, _} = Accounts.check_password(user, "password")
    end

    test "create_user/1 fails with no password" do
      assert {:error, changeset} = Accounts.create_user(Enum.into(%{password: ""}, @valid_attrs))
      assert errors_on(changeset).password_hash
    end

    test "check_password fails for invalid password" do
      assert user = user_fixture(%{password: "hello_world"})
      assert {:error, _user} = Accounts.check_password(user, "hello_w0rld")
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.balance == 43
      assert user.email == "some updated email"
      assert user.first_name == "some updated first name"
      assert user.last_name == "some updated last name"
    end

    test "update_user_profile/2 update roles" do
      user = user_fixture() |> assign_role("admin")
      role_fixture(%{slug: "student"})
      assert {:ok, user} = Accounts.update_user_profile(user, %{}, ["student"], [])

      role =
        assoc(user, :roles)
        |> Repo.all()
        |> List.first()

      assert role.slug == "student"
    end

    test "update_user_profile/2 update flyer certificates" do
      user = user_fixture() |> assign_role("admin")
      flyer_certificate_fixture(%{slug: "cfi"})
      assert {:ok, user} = Accounts.update_user_profile(user, %{}, ["admin"], ["cfi"])

      cert =
        assoc(user, :flyer_certificates)
        |> Repo.all()
        |> List.first()

      assert cert.slug == "cfi"
    end

    test "update_user_profile/2 updates date" do
      user = user_fixture() |> assign_role("admin")
      role_fixture(%{slug: "student"})

      assert {:ok, user} =
               Accounts.update_user_profile(
                 user,
                 %{"medical_expires_at" => "3/3/2018"},
                 [
                   "student"
                 ],
                 []
               )

      assert user.medical_expires_at == ~D[2018-03-03]
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
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

  # describe "flyer_details" do
  #   alias Flight.Accounts.FlyerDetails
  #
  #   test "get_flyer_details_for_user_id gets default if none exists" do
  #     user = user_fixture()
  #     assert Accounts.get_flyer_details_for_user_id(user.id) == FlyerDetails.default()
  #   end
  #
  #   test "get_flyer_details_for_user_id gets existing details" do
  #     details = flyer_details_fixture(%{address_1: "the moon"})
  #
  #     assert %FlyerDetails{address_1: "the moon"} =
  #              Accounts.get_flyer_details_for_user_id(details.user.id)
  #   end
  #
  #   test "set_flyer_details_for_user sets flyer details" do
  #     user = user_fixture()
  #
  #     {:ok, %FlyerDetails{} = flyer_details} =
  #       Accounts.set_flyer_details_for_user(
  #         %{
  #           address_1: "1234 Hi",
  #           city: "Bigfork",
  #           state: "MT",
  #           faa_tracking_number: "ABC1234"
  #         },
  #         user
  #       )
  #
  #     assert flyer_details.address_1 == "1234 Hi"
  #     assert flyer_details.city == "Bigfork"
  #     assert flyer_details.state == "MT"
  #     assert flyer_details.faa_tracking_number == "ABC1234"
  #   end
  #
  #   test "set_flyer_details_for_user when details already exist" do
  #     user = user_fixture()
  #     flyer_details_fixture(%{}, user)
  #
  #     {:ok, %FlyerDetails{} = flyer_details} =
  #       Accounts.set_flyer_details_for_user(
  #         %{
  #           address_1: "Herro"
  #         },
  #         user
  #       )
  #
  #     assert flyer_details.address_1 == "Herro"
  #   end
  # end
end
