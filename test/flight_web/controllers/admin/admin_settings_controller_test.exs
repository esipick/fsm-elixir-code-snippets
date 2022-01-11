defmodule FlightWeb.Admin.SettingsControllerTest do
  use FlightWeb.ConnCase

  alias Flight.Accounts.School

  describe "GET /admin/settings/:id" do
    test "renders", %{conn: conn} do
      first_school = school_fixture(%{name: "first school"})
      admin = admin_fixture(%{}, first_school)

      second_school = school_fixture(%{name: "second school"})
      superadmin = superadmin_fixture(%{}, second_school)

      conn =
        conn
        |> web_auth_admin(admin)

      content =
        conn
        |> get("/admin/settings/#{first_school.id}")

      assert redirected_to(content) == "/admin/settings"

      conn =
        conn
        |> web_auth_superadmin(superadmin)

      content =
        conn
        |> get("/admin/settings/#{first_school.id}")
        |> html_response(200)

      assert content =~ "value=\"first school\""

      content =
        conn
        |> get("/admin/settings/#{second_school.id}")
        |> html_response(200)

      assert content =~ "value=\"second school\""
    end
  end

  describe "GET /admin/settings" do
    test "renders school info", %{conn: conn} do
      conn
      |> web_auth_admin()
      |> get("/admin/settings")
      |> html_response(200)
    end

    test "renders contact info", %{conn: conn} do
      conn
      |> web_auth_admin()
      |> get("/admin/settings?tab=contact")
      |> html_response(200)
    end

    test "renders payment setup", %{conn: conn} do
      conn
      |> web_auth_admin()
      |> get("/admin/settings?tab=payment")
      |> html_response(200)
    end

    test "renders billing settings", %{conn: conn} do
      conn
      |> web_auth_admin()
      |> get("/admin/settings?tab=billing")
      |> html_response(200)
    end

    test "renders profile settings", %{conn: conn} do
      conn
      |> web_auth_admin()
      |> get("/admin/settings?tab=profile")
      |> html_response(200)
    end

    test "redirects dispatcher", %{conn: conn} do
      conn =
        conn
        |> web_auth_dispatcher()
        |> get("/admin/settings?tab=billing")

      assert redirected_to(conn) == "/admin/home"
    end
  end

  describe "PUT /admin/settings/:id" do
    test "renders", %{conn: conn} do
      first_school = school_fixture(%{name: "first school"})
      admin = admin_fixture(%{}, first_school)

      second_school = school_fixture(%{name: "second school"})
      superadmin = superadmin_fixture(%{}, second_school)

      params = %{
        data: %{
          name: "another name"
        },
        redirect_tab: "school"
      }

      first_school_path = "/admin/settings/#{first_school.id}"

      conn =
        conn
        |> web_auth_admin(admin)

      content =
        conn
        |> put(first_school_path, params)

      assert redirected_to(content) == "/admin/settings"
      refute Flight.Repo.get(School, first_school.id).name == "another name"

      conn =
        conn
        |> web_auth_superadmin(superadmin)

      content =
        conn
        |> put(first_school_path, params)

      assert redirected_to(content) == "#{first_school_path}?tab=school"
      assert Flight.Repo.get(School, first_school.id).name == "another name"

      second_school_path = "/admin/settings/#{second_school.id}"

      content =
        conn
        |> put(second_school_path, params)

      assert redirected_to(content) == "#{second_school_path}?tab=school"
      assert Flight.Repo.get(School, second_school.id).name == "another name"
    end
  end

  describe "PUT /admin/settings" do
    test "updates school, redirects to school", %{conn: conn} do
      school = school_fixture(%{name: "Initial name"})
      admin = admin_fixture(%{}, school)

      params = %{
        data: %{
          name: "Another name"
        },
        redirect_tab: "school"
      }

      conn =
        conn
        |> web_auth(admin)
        |> put("/admin/settings", params)

      assert redirected_to(conn) == "/admin/settings?tab=school"

      assert refresh(admin.school).name
    end

    test "redirects to contact", %{conn: conn} do
      school = school_fixture(%{name: "Initial name"})
      admin = admin_fixture(%{}, school)

      params = %{
        data: %{
          name: "Another name"
        },
        redirect_tab: "contact"
      }

      conn =
        conn
        |> web_auth(admin)
        |> put("/admin/settings", params)

      assert redirected_to(conn) == "/admin/settings?tab=contact"
    end
  end
end
