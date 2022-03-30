defmodule FlightWeb.Admin.SquawkController do
  use FlightWeb, :controller

  plug(:allow_only_admin when action in [:new, :create, :edit, :update, :delete])
  plug(:get_aircraft when action in [:create, :new])
  plug(:get_squawk when action in [:edit, :update, :delete])

  alias Flight.Repo
  alias Flight.Accounts.Role
  alias Flight.Auth.Authorization
  alias Flight.Scheduling
  alias Flight.Scheduling.{Aircraft}
  alias Fsm.Squawks.Squawk
  alias Fsm.Squawks
  alias Fsm.Attachments.Attachment

  def create(conn, %{"squawk" => squawk}) do
    user_id = conn.assigns.current_user.id
    aircraft_id = Map.get(squawk, "aircraft_id")
    squawk_input =
      squawk
      |> transform_squawk
      |> Map.put(:user_id, user_id)

    attachments = Map.get(squawk, "attachments") || []

    with {:ok, _} <- Fsm.AttachmentUploader.validate_attachment(attachments),
      {:ok, %{id: id} = squawk_changeset} <- Squawks.add_squawk(squawk_input, nil, nil) do

        Fsm.AttachmentUploader.upload_files_to_s3(id, attachments)
        |> case do
          {:error, msg} ->
            Squawks.delete_squawk(squawk_changeset)
            render_squawk_error(conn, squawk_input, msg)

          {:ok, attachments} ->
            attachments =
              Enum.map(attachments, fn attch ->
                attch
                |> Map.put(:attachment_type, :squawk)
                |> Map.put(:user_id, user_id)
                |> Map.put(:squawk_id, id)
              end)

            Squawks.add_multiple_squawk_images(attachments)
            |> case do
              {:error, error} ->
                Squawks.delete_squawk(squawk_changeset)
                render_squawk_error(conn, squawk_input, "Couldn't create squawk attachment. Please try again")

              {:ok, _attachments_changeset} ->
                conn
                |> put_flash(:success, "Successfully created squawk")
                |> redirect(to: "/admin/aircrafts/#{aircraft_id}")
            end
        end
    else
      {:error, %Squawk{} = changeset} -> render_squawk_error(conn, changeset)
      {:error, msg} ->
        render_squawk_error(conn, squawk_input, msg)
    end
  end

  def new(conn, _params) do
    changeset = Squawk.new_changeset()

    render(
      conn,
      "new.html",
      asset_namespace: asset_namespace(conn.assigns.aircraft),
      aircraft: conn.assigns.aircraft,
      changeset: changeset,
      skip_shool_select: true
    )
  end

  def edit(conn, _params) do
    squawk =
      conn.assigns.squawk
      |> Map.from_struct()

    render(
      conn,
      "edit.html",
      squawk: squawk,
      changeset: Squawk.new_changeset(),
      skip_shool_select: true
    )
  end

  def update(conn, %{"squawk" => squawk}) do
    squawk_input = transform_squawk(squawk)
    changeset = conn.assigns.squawk

    Squawks.update_squawk(changeset, squawk_input)
    |> case do
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Couldn't update squawk.")
        |> render("edit.html", squawk: changeset, changeset: changeset, skip_school_select: true)

      {:ok, changeset} ->
        conn
        |> put_flash(:success, "Successfully updated squawk")
        |> redirect(to: "/admin/aircrafts/#{changeset.aircraft_id}")
    end
  end

  def delete(conn, _) do
    squawk = conn.assigns.squawk
    Squawks.delete_squawk(squawk)
    
    conn
    |> put_flash(:success, "Squawk deleted")
    |> redirect(to: "/admin/aircrafts/#{squawk.aircraft_id}")
  end

  defp allow_only_admin(conn, _) do
    user = Repo.preload(conn.assigns.current_user, [:roles])
    roles = Role |> Flight.Repo.all()

    if Authorization.is_admin?(user) do
      conn
    else
      Authorization.Extensions.redirect_unathorized_user(conn)
    end
  end

  defp get_aircraft(conn, _) do
    vehicle_id = conn.params["aircraft_id"] || conn.params["simulator_id"]
    aircraft = Scheduling.get_aircraft(vehicle_id, conn)

    cond do
      aircraft && !aircraft.archived ->
        assign(conn, :aircraft, aircraft)

      aircraft && aircraft.archived ->
        redirect_from_deleted_asset_page(aircraft)

      true ->
        conn
        |> put_flash(:error, "Unknown asset.")
        |> redirect(to: "/admin/aircrafts")
        |> halt()
    end
  end

  defp get_squawk(conn, _) do
    id =
      Integer.parse((conn.params["id"] || ""))
      |> case do
        :error -> -1
        {int_id, _} -> int_id
      end

    squawk = Squawks.get_squawk(id)

    if squawk do
      squawk = Repo.preload(squawk, [:attachments])
      assign(conn, :squawk, squawk)

    else
      conn
      |> put_flash(:error, "Squawk does not exists or already removed.")
      |> redirect(to: "/admin/aircrafts")
      |> halt()
    end
  end

  defp redirect_from_deleted_asset_page(conn, aircraft \\ nil) do
    conn
    |> put_flash(:error, "#{Aircraft.display_name(aircraft)} already removed.")
    |> redirect(to: "/admin/#{asset_namespace(aircraft)}")
    |> halt()
  end

  defp render_squawk_error(conn, %Squawk{} = changeset) do
    render(
      conn |> put_flash(:error, "Couldn't create squawk, please try again."),
      "new.html",
      asset_namespace: asset_namespace(conn.assigns.aircraft),
      aircraft: conn.assigns.aircraft,
      changeset: changeset,
      skip_shool_select: true
    )
  end

  defp render_squawk_error(conn, squawk, error) do
    changeset = prepare_changeset(squawk)
    render(
      conn |> put_flash(:error, error),
      "new.html",
      asset_namespace: asset_namespace(conn.assigns.aircraft),
      aircraft: conn.assigns.aircraft,
      changeset: changeset,
      skip_shool_select: true
    )
  end

  defp redirect_to_asset(conn, squawk) do
    aircraft = Repo.preload(squawk, :aircraft).aircraft
    namespace = asset_namespace(squawk)

    conn
    |> put_flash(:success, "Successfully created squawk")
    |> redirect(to: "/admin/#{namespace}/#{aircraft.id}")
  end

  defp asset_namespace(aircraft) do
    (Aircraft.display_name(aircraft) |> String.downcase()) <> "s"
  end

  defp prepare_changeset(squawk_data) do
    changeset = Squawk.new_changeset()
    changeset = Map.put(changeset, :data, Map.merge(changeset.data, squawk_data))
  end

  defp transform_squawk(squawk) do
    aircraft_id = Map.get(squawk, "aircraft_id")
    title = Map.get(squawk, "title")
    description = Map.get(squawk, "description")
    severity = Map.get(squawk, "severity")
    system_affected = Map.get(squawk, "system_affected")

    %{
      aircraft_id: aircraft_id,
      title: title,
      description: description,
      severity: string_to_atom(severity),
      system_affected: string_to_atom(system_affected)
    }
  end

  defp string_to_atom(nil), do: :nan
  defp string_to_atom(str) do
    try do
      "#{str}"
      |> String.downcase
      |> String.to_existing_atom
    rescue
      _argError ->
        "#{str}"
        |> String.downcase
        |> String.to_atom
    end
  end
end
