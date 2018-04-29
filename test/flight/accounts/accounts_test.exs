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

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "flyer_details" do
    alias Flight.Accounts.FlyerDetails

    test "get_flyer_details_for_user_id gets default if none exists" do
      user = user_fixture()
      assert Accounts.get_flyer_details_for_user_id(user.id) == FlyerDetails.default()
    end

    test "get_flyer_details_for_user_id gets existing details" do
      details = flyer_details_fixture(%{address_1: "the moon"})

      assert %FlyerDetails{address_1: "the moon"} =
               Accounts.get_flyer_details_for_user_id(details.user.id)
    end

    test "set_flyer_details_for_user sets flyer details" do
      user = user_fixture()

      {:ok, %FlyerDetails{} = flyer_details} =
        Accounts.set_flyer_details_for_user(
          %{
            address_1: "1234 Hi",
            city: "Bigfork",
            state: "MT",
            faa_tracking_number: "ABC1234"
          },
          user
        )

      assert flyer_details.address_1 == "1234 Hi"
      assert flyer_details.city == "Bigfork"
      assert flyer_details.state == "MT"
      assert flyer_details.faa_tracking_number == "ABC1234"
    end

    test "set_flyer_details_for_user when details already exist" do
      user = user_fixture()
      flyer_details_fixture(%{}, user)

      {:ok, %FlyerDetails{} = flyer_details} =
        Accounts.set_flyer_details_for_user(
          %{
            address_1: "Herro"
          },
          user
        )

      assert flyer_details.address_1 == "Herro"
    end
  end
end
