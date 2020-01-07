defmodule FlightWeb.Admin.SettingsControllerTest do
  use FlightWeb.ConnCase

  describe "GET /admin/settings/:id" do
    test "renders", %{conn: conn} do
      first_school = school_fixture(%{name: "first school"})
      admin = admin_fixture(%{}, first_school)

      second_school = school_fixture(%{name: "second school"})
      superadmin = superadmin_fixture(%{}, second_school)

      conn =
        conn
        |> web_auth_admin()

      content =
        conn
        |> get("/admin/settings/#{first_school.id}")

      assert redirected_to(content) == "/admin/settings"

      conn =
        conn
        |> web_auth_superadmin()

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

    test "renders billing info", %{conn: conn} do
      conn
      |> web_auth_admin()
      |> get("/admin/settings?tab=billing")
      |> html_response(200)
    end

    test "redirects dispatcher", %{conn: conn} do
      conn =
        conn
        |> web_auth_dispatcher()
        |> get("/admin/settings?tab=billing")

      assert redirected_to(conn) == "/admin/dashboard"
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

      assert redirected_to(conn) == "/admin/settings"

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
