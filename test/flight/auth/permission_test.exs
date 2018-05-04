defmodule Flight.Auth.PermissionTest do
  use Flight.DataCase

  alias Flight.Auth.Permission

  describe "users" do
    test "personal" do
      user = user_fixture()
      assert Permission.personal_scope_checker(user, :users, user)
    end

    test "personal fails" do
      other_user = user_fixture()
      user = user_fixture()
      refute Permission.personal_scope_checker(other_user, :users, user)
    end
  end

  describe "personal_scope_checker" do
    test "invalid" do
      assert_raise(RuntimeError, fn ->
        Permission.personal_scope_checker(user_fixture(), :foo, :bar)
      end)
    end
  end

  describe "permission_slug" do
    test "personal scope" do
      assert Permission.permission_slug(Permission.new(:users, :modify, {:personal, nil})) ==
               "users:modify:personal"
    end

    test "all scope" do
      assert Permission.permission_slug(Permission.new(:users, :modify, :all)) ==
               "users:modify:all"
    end

    test "resource verb simple_scope" do
      assert Permission.permission_slug(:users, :modify, :personal) == "users:modify:personal"
    end
  end

  describe "checker" do
    test "all" do
      permission = Permission.new(:users, :modify, :all)
      assert Permission.scope_checker(permission, user_fixture())
    end

    test "personal" do
      user = user_fixture()
      perm = Permission.new(:users, :modify, {:personal, user})

      assert Permission.scope_checker(perm, user) ==
               Permission.personal_scope_checker(user, :users, user)
    end
  end
end
