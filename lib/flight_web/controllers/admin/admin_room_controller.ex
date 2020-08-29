defmodule FlightWeb.Admin.RoomController do
  use FlightWeb, :controller

  alias Flight.SchoolAssets
  alias Flight.SchoolAssets.Room

  import FlightWeb.Admin.AssetsHelper

  plug(:get_room when action in [:show, :edit, :update, :delete])

  def create(conn, %{"data" => room_data}) do
    redirect_to = get_redirect_param(room_data)

    case Room.create(room_data, conn) do
      {:ok, room} ->
        conn
        |> put_flash(:success, "Successfully created room.")
        |> redirect(to: redirect_to || "/admin/rooms/#{room.id}")

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset, redirect_to: redirect_to)
    end
  end

  def new(conn, params) do
    conn
    |> render(
      "new.html",
      redirect_to: params["redirect_to"],
      changeset: Room.changeset(%Room{}, %{})
    )
  end

  def show(conn, _params) do
    conn
    |> render("show.html", room: conn.assigns.room, skip_shool_select: true)
  end

  def index(conn, params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.RoomListData.build(conn, page_params, search_term)
    message = params["search"] && set_message(params["search"])

    conn
    |> render("index.html", data: data, message: message, tab: :room)
  end

  def edit(conn, params) do
    conn
    |> render(
      "edit.html",
      changeset: Room.changeset(conn.assigns.room, %{}),
      skip_shool_select: true,
      redirect_to: params["redirect_to"]
    )
  end

  def update(conn, %{"data" => room_data}) do
    redirect_to = get_redirect_param(room_data)

    case Room.update(conn.assigns.room, room_data) do
      {:ok, room} ->
        conn
        |> put_flash(:success, "Successfully updated room.")
        |> redirect(to: redirect_to || "/admin/rooms/#{room.id}")

      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset, redirect_to: redirect_to)
    end
  end

  def delete(conn, params) do
    Room.archive!(conn.assigns.room)

    conn
    |> put_flash(:success, "Room successfully archived.")
    |> redirect(to: params["redirect_to"] || "/admin/rooms")
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


  defp set_message(search_param) do
    if String.trim(search_param) == "" do
      "Please fill out search field"
    end
  end
end
