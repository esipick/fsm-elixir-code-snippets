defmodule FlightWeb.Admin.RoomController do
  use FlightWeb, :controller

  alias Flight.SchoolAssets
  alias Flight.SchoolAssets.Room

  plug(:get_room when action in [:show, :edit, :update, :delete])

  def create(conn, %{"data" => room_data}) do
    case Room.create(room_data, conn) do
      {:ok, room} ->
        conn
        |> put_flash(:success, "Successfully created room.")
        |> redirect(to: "/admin/rooms/#{room.id}")

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  def new(conn, _params) do
    conn
    |> render(
      "new.html",
      changeset: Room.changeset(%Room{}, %{})
    )
  end

  def show(conn, _params) do
    conn
    |> render("show.html", room: conn.assigns.room, skip_shool_select: true)
  end

  def index(conn, params) do
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.RoomListData.build(conn, page_params)

    conn
    |> render("index.html", data: data, tab: :room)
  end

  def edit(conn, _params) do
    conn
    |> render(
      "edit.html",
      changeset: Room.changeset(conn.assigns.room, %{}),
      skip_shool_select: true
    )
  end

  def update(conn, %{"data" => room_data}) do
    case Room.update(conn.assigns.room, room_data) do
      {:ok, room} ->
        conn
        |> put_flash(:success, "Successfully updated room.")
        |> redirect(to: "/admin/rooms/#{room.id}")

      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    Room.archive!(conn.assigns.room)

    conn
    |> put_flash(:success, "Room successfully archived.")
    |> redirect(to: "/admin/rooms")
  end

  defp get_room(conn, _) do
    room = SchoolAssets.get_room(conn.params["id"] || conn.params["room_id"], conn)

    cond do
      room && !room.archived ->
        assign(conn, :room, room)

      room && room.archived ->
        conn
        |> put_flash(:error, "Room already removed.")
        |> redirect(to: "/admin/rooms")
        |> halt()

      true ->
        conn
        |> put_flash(:error, "Unknown room.")
        |> redirect(to: "/admin/rooms")
        |> halt()
    end
  end
end
