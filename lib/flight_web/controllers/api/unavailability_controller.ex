defmodule FlightWeb.API.UnavailabilityController do
  use FlightWeb, :controller

  plug(:get_unavailability when action in [:update, :show, :delete])
  plug(:authorize_modify when action in [:create, :update, :delete])

  alias Flight.Scheduling
  import Flight.Auth.Authorization
  alias Flight.Auth.Permission

  def index(conn, params) do
    unavailabilities =
      Scheduling.get_unavailabilities(params, conn)
      |> FlightWeb.API.UnavailabilityView.preload()

    render(conn, "index.json", unavailabilities: unavailabilities)
  end

  def show(conn, _) do
    unavailability = FlightWeb.API.UnavailabilityView.preload(conn.assigns.unavailability)

    render(conn, "show.json", unavailability: unavailability)
  end

  def create(conn, %{"data" => unavailability_data}) do
    case Flight.Scheduling.insert_or_update_unavailability(
           %Scheduling.Unavailability{},
           unavailability_data,
           conn
         ) do
      {:ok, unavailability} ->
        unavailability = FlightWeb.API.UnavailabilityView.preload(unavailability)
        render(conn, "show.json", unavailability: unavailability)

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def update(conn, %{"data" => unavailability_data}) do
    case Flight.Scheduling.insert_or_update_unavailability(
           conn.assigns.unavailability,
           unavailability_data,
           conn
         ) do
      {:ok, unavailability} ->
        unavailability = FlightWeb.API.UnavailabilityView.preload(unavailability)
        render(conn, "show.json", unavailability: unavailability)

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def delete(conn, _) do
    Scheduling.delete_unavailability(conn.assigns.unavailability.id, conn)

    conn
    |> resp(204, "")
  end

  def authorize_modify(conn, _) do
    instructor_user_id_from_unavailability =
      case conn.assigns do
        %{unavailability: %{instructor_user_id: id}} -> id
        _ -> nil
      end

    instructor_user_id =
      conn.params["data"] |> Optional.map(& &1["instructor_user_id"]) ||
        instructor_user_id_from_unavailability

    cond do
      parse_to_boolean(instructor_user_id) ->
        if user_can?(conn.assigns.current_user, [
             Permission.new(:unavailability_instructor, :modify, {:personal, instructor_user_id}),
             Permission.new(:unavailability_instructor, :modify, :all),
             Permission.new(:unavailability, :modify, :all)
           ]) do
          conn
        else
          render_bad_request(
            conn,
            "You don't have permissions for this action."
          )
        end

      user_can?(conn.assigns.current_user, [
        Permission.new(:unavailability_aircraft, :modify, :all),
        Permission.new(:unavailability_instructor, :modify, :all),
        Permission.new(:unavailability, :modify, :all)
      ]) ->
        conn

      true ->
        render_bad_request(
          conn,
          "You don't have permissions for this action."
        )
    end
  end

  def render_bad_request(
        conn,
        message \\ "You are not authorized to create or change this unavailability. Please talk to your school's Admin."
      ) do
    conn
    |> put_status(400)
    |> json(%{human_errors: [message]})
    |> halt()
  end

  defp get_unavailability(conn, _) do
    assign(conn, :unavailability, Scheduling.get_unavailability(conn.params["id"], conn))
  end

  defp parse_to_boolean(instructor_user_id) do
    case instructor_user_id do
      nil -> nil
      "" -> nil
      _ -> true
    end
  end
end
