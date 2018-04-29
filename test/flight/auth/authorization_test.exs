defmodule Flight.Auth.AuthorizationTest do
  use FlightWeb.ConnCase

  import Flight.Auth.Authorization
  alias Flight.Auth.Permission

  describe "permissions_for_role_slug" do
    test "admin" do
      assert permissions_for_role_slug("admin") == admin_permission_slugs()
    end

    test "instructor" do
      assert permissions_for_role_slug("instructor") == instructor_permission_slugs()
    end

    test "student" do
      assert permissions_for_role_slug("student") == student_permission_slugs()
    end

    test "renter" do
      assert permissions_for_role_slug("renter") == renter_permission_slugs()
    end
  end

  describe "permission_slugs_for_user" do
    test "single role" do
      user = user_fixture() |> assign_role("student")
      assert permission_slugs_for_user(user) == student_permission_slugs()
    end

    test "multiple roles" do
      user = user_fixture() |> assign_roles(["admin", "instructor"])

      assert permission_slugs_for_user(user) ==
               MapSet.union(instructor_permission_slugs(), admin_permission_slugs())
    end
  end

  describe "has_permission_slug?" do
    test "true if has slug" do
      user = user_fixture() |> assign_role("student")

      assert has_permission_slug?(
               user,
               Permission.permission_slug(:flyer_details, :modify, :personal)
             )
    end

    test "false if doesn't have slug" do
      user = user_fixture() |> assign_role("student")
      refute has_permission_slug?(user, "foo")
    end
  end

  describe "user_can?" do
    test "true if user has permission" do
      user = user_fixture() |> assign_role("student")
      details = flyer_details_fixture(%{}, user)
      assert user_can?(user, [Permission.new(:flyer_details, :view, {:personal, details})])
    end

    test "true if user has at least one permission" do
      user = user_fixture() |> assign_role("student")
      details = flyer_details_fixture(%{}, user)

      assert user_can?(user, [
               Permission.new(:flyer_details, :view, {:personal, details}),
               Permission.new(:flyer_details, :view, :all)
             ])
    end

    test "false if role doesn't have permission" do
      user = user_fixture() |> assign_role("student")
      refute user_can?(user, [Permission.new(:flyer_details, :view, :all)])
    end

    test "false if no permissions" do
      user = user_fixture() |> assign_role("student")
      refute user_can?(user, [])
    end
  end

  describe "halt_unless_user_can?" do
    test "returns conn if no func and user has permission", %{conn: conn} do
      user = user_fixture() |> assign_role("student")
      details = flyer_details_fixture(%{}, user)
      conn = assign(conn, :current_user, user)

      assert %Plug.Conn{halted: false} =
               halt_unless_user_can?(conn, [
                 Permission.new(:flyer_details, :view, {:personal, details})
               ])
    end

    test "returns whatever the func returns if passed", %{conn: conn} do
      user = user_fixture() |> assign_role("student")
      details = flyer_details_fixture(%{}, user)
      conn = assign(conn, :current_user, user)

      assert halt_unless_user_can?(
               conn,
               [
                 Permission.new(:flyer_details, :view, {:personal, details})
               ],
               fn -> :foo end
             ) == :foo
    end

    test "returns halted conn if user doesn't have permission", %{conn: conn} do
      user = user_fixture() |> assign_role("student")
      conn = assign(conn, :current_user, user)

      assert %Plug.Conn{halted: true, status: 401} =
               halt_unless_user_can?(conn, [
                 Permission.new(:flyer_details, :view, :all)
               ])
    end
  end
end
