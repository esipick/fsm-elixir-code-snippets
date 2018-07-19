defmodule FlightWeb.Admin.SettingsControllerTest do
  use FlightWeb.ConnCase

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
