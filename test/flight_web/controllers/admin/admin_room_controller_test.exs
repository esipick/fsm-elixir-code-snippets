defmodule FlightWeb.Admin.RoomControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Repo
  alias Flight.SchoolAssets.Room

  describe "GET /admin/rooms as superadmin" do
    test "renders", %{conn: conn} do
      school = school_fixture()
      room = room_fixture(%{}, school)
      another_school = school_fixture(%{location: "7 Park Avenue 2a"})
      another_room = room_fixture(%{location: "another room location"}, another_school)

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/rooms")
        |> html_response(200)

      refute content =~ "<th>School</th>"
      refute content =~ room.location
      refute content =~ another_room.location

      conn =
        conn
        |> web_auth(superadmin_fixture(%{}, school))

      content =
        conn
        |> get("/admin/rooms")
        |> html_response(200)

      assert content =~ "<th>School</th>"
      assert content =~ room.location
      assert content =~ "<a href=\"/admin/schools/#{school.id}\">#{school.name}</a>"
      refute content =~ another_room.location

      refute content =~
               "<a href=\"/admin/schools/#{another_school.id}\">#{another_school.name}</a>"

      content =
        conn
        |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
        |> get("/admin/rooms")
        |> html_response(200)

      assert content =~ another_room.location

      assert content =~
               "<a href=\"/admin/schools/#{another_school.id}\">#{another_school.name}</a>"

      refute content =~ room.location
      refute content =~ "<a href=\"/admin/schools/#{school.id}\">#{school.name}</a>"
    end
  end

  describe "GET /admin/room" do
    test "renders", %{conn: conn} do
      room = room_fixture()

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/rooms")
        |> html_response(200)

      refute content =~ "<th>School</th>"
      assert content =~ room.location
    end
  end

  describe "GET /admin/rooms/new" do
    test "renders", %{conn: conn} do
      html =
        conn
        |> web_auth_admin()
        |> get("/admin/rooms/new")
        |> html_response(200)

      assert html =~ "action=\"/admin/rooms\""
    end
  end

  describe "POST /admin/rooms" do
    test "creates room", %{conn: conn} do
      room = room_fixture()

      new_room =
        %{Map.from_struct(room) | location: "Some Crazy Make Yo"}
        |> Map.delete(:id)

      payload = %{
        data: new_room
      }

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/rooms", payload)

      assert %Room{id: id} = Repo.get_by(Room, location: "Some Crazy Make Yo")

      response_redirected_to(conn, "/admin/rooms/#{id}")
    end

    test "fails to create room", %{conn: conn} do
      room = room_fixture()
      new_room = %{Map.from_struct(room) | location: "Some Crazy Make", resources: nil}

      payload = %{
        data: new_room
      }

      conn
      |> web_auth_admin()
      |> post("/admin/rooms", payload)
      |> html_response(200)

      refute Repo.get_by(Room, location: "Some Crazy Make")
    end
  end

  describe "GET /admin/rooms/:id as superadmin" do
    test "renders", %{conn: conn} do
      school = school_fixture()
      room = room_fixture(%{}, school)
      another_school = school_fixture()
      another_room = room_fixture(%{}, another_school)

      conn =
        conn
        |> web_auth(superadmin_fixture(%{}, school))

      conn
      |> get("/admin/rooms/#{room.id}")
      |> html_response(200)

      conn
      |> get("/admin/rooms/#{another_room.id}")
      |> response_redirected_to("/admin/rooms")

      conn
      |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
      |> get("/admin/rooms/#{another_room.id}")
      |> html_response(200)
    end
  end

  describe "GET /admin/rooms/:id" do
    test "renders", %{conn: conn} do
      room = room_fixture()

      conn
      |> web_auth_admin()
      |> get("/admin/rooms/#{room.id}")
      |> html_response(200)
    end
  end

  describe "GET /admin/rooms/:id/edit" do
    test "renders", %{conn: conn} do
      room = room_fixture()

      html =
        conn
        |> web_auth_admin()
        |> get("/admin/rooms/#{room.id}/edit")
        |> html_response(200)

      assert html =~ "action=\"/admin/rooms/#{room.id}\""
    end
  end

  describe "PUT /admin/rooms/:id" do
    test "updates room", %{conn: conn} do
      room = room_fixture()
      room_payload = %{Map.from_struct(room) | location: "Some Crazy Make"}

      payload = %{
        data: room_payload
      }

      conn
      |> web_auth_admin()
      |> put("/admin/rooms/#{room.id}", payload)
      |> response_redirected_to("/admin/rooms/#{room.id}")

      assert %Room{} = Repo.get_by(Room, location: "Some Crazy Make", id: room.id)
    end

    test "show error when room already removed", %{conn: conn} do
      room = room_fixture()
      room_payload = %{Map.from_struct(room) | location: "Some Crazy Make"}

      payload = %{
        data: room_payload
      }

      Room.archive!(room)

      conn =
        conn
        |> web_auth_admin()
        |> put("/admin/rooms/#{room.id}", payload)
        |> response_redirected_to("/admin/rooms")

      conn
      |> get("/admin/rooms")
      |> html_response(200)

      assert get_flash(conn, :error) =~ "Room already removed."
    end
  end
end
