defmodule Flight.Auth.PermissionTest do
  use Flight.DataCase

  alias Flight.Auth.Permission

  describe "flyer_details" do
    test "personal" do
      details = flyer_details_fixture()
      assert Permission.personal_scope_checker(details.user, :flyer_details, details)
    end

    test "personal fails" do
      other_user = user_fixture()
      details = flyer_details_fixture()
      refute Permission.personal_scope_checker(other_user, :flyer_details, details)
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
      assert Permission.permission_slug(Permission.new(:flyer_details, :modify, {:personal, nil})) ==
               "flyer_details:modify:personal"
    end

    test "all scope" do
      assert Permission.permission_slug(Permission.new(:flyer_details, :modify, :all)) ==
               "flyer_details:modify:all"
    end

    test "resource verb simple_scope" do
      assert Permission.permission_slug(:flyer_details, :modify, :personal) ==
               "flyer_details:modify:personal"
    end
  end

  describe "checker" do
    test "all" do
      permission = Permission.new(:flyer_details, :modify, :all)
      assert Permission.scope_checker(permission, user_fixture())
    end

    test "personal" do
      details = flyer_details_fixture()
      perm = Permission.new(:flyer_details, :modify, {:personal, details})

      assert Permission.scope_checker(perm, details.user) ==
               Permission.personal_scope_checker(details.user, :flyer_details, details)
    end
  end
end
