defmodule FlightWeb.API.UserController do
  use FlightWeb, :controller

  alias Flight.Accounts
  alias Flight.Accounts.Role
  alias Flight.Auth.Permission
  import Flight.Auth.Authorization

  plug(FlightWeb.AuthenticateApiUser)
  plug(:get_user when action in [:show, :update, :form_items])
  plug(:authorize_modify when action in [:update, :form_items])
  plug(:authorize_view when action in [:show])
  plug(:authorize_create when action in [:create])
  plug(:authorize_view_all when action in [:autocomplete])

  def index(conn, %{"form" => form}) do
    result =
      case form do
        "directory" ->
          users =
            Accounts.get_directory_users_visible_to_user(conn)
            |> Flight.Repo.preload(:roles)
            |> Enum.sort_by(& &1.last_name)

          {:ok, users, "directory_user.json"}

        _ ->
          :error
      end

    case result do
      {:ok, users, form} ->
        render(conn, "index.json", users: users, form: form)

      :error ->
        conn
        |> put_status(400)
        |> json(%{error: %{message: "Invalid form"}})
    end
  end

  def show(conn, _params) do
    user =
      conn.assigns.user
      |> FlightWeb.API.UserView.show_preload()

    render(conn, "show.json", user: user)
  end

  def create(conn, %{"data" => data_params, "role_id" => role_id} = params) do
    data_params = Map.put(data_params, "password", Flight.Random.string(20))
    role = fetch_user_role(role_id, conn)

    case Accounts.CreateUserWithInvitation.run(
           data_params,
           conn,
           role,
           !!params["stripe_token"],
           params["stripe_token"]
         ) do
      {:ok, user} ->
        user =
          user
          |> FlightWeb.API.UserView.show_preload()

        render(conn, "show.json", user: user)

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def change_password(conn, %{"data" => %{"password" => password}}) do
    with {:ok, user} <- Accounts.set_password(conn.assigns.current_user, password) do
      user =
        user
        |> FlightWeb.API.UserView.show_preload()

      render(conn, "show.json", user: user)
    else
      {:error, changeset} ->
        IO.inspect(changeset)

        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def update(conn, %{"data" => data_params}) do
    with {:ok, user} <-
           Accounts.api_update_user_profile(
             conn.assigns.user,
             data_params,
             data_params["flyer_certificates"]
           ) do
      user =
        user
        |> FlightWeb.API.UserView.show_preload()

      render(conn, "show.json", user: user)
    else
      {:error, changeset} ->
        IO.inspect(changeset)

        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def form_items(conn, _params) do
    items =
      conn.assigns.user
      |> Accounts.editable_fields()
      |> Enum.map(&FlightWeb.UserForm.item(conn.assigns.user, &1))

    render(conn, "form_items.json", form_items: items)
  end

  def autocomplete(conn, %{"name" => name} = params) do
    role_slug = Map.get(params, "role", "student")
    role = Flight.Accounts.role_for_slug(role_slug)
    users = Flight.Queries.User.search_users_by_name(name, role, conn)

    render(conn, "autocomplete.json", users: users)
  end

  def by_role(conn, %{"role" => role_slug} = _params) do
    role = Flight.Accounts.role_for_slug(role_slug)
    users = Flight.Queries.User.get_users_by_role(role, conn)

    render(conn, "autocomplete.json", users: users)
  end

  def authorize_modify(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:users, :modify, {:personal, conn.assigns.user}),
      Permission.new(:users, :modify, :all)
    ])
  end

  def authorize_view(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:users, :view, {:personal, conn.assigns.user}),
      Permission.new(:users, :view, :all)
    ])
  end

  def authorize_view_all(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:users, :view, :all)])
  end

  def authorize_create(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:users, :create, :all)])
  end

  defp get_user(conn, _) do
    assign(conn, :user, Accounts.get_user(conn.params["id"] || conn.params["user_id"], conn))
  end

  defp fetch_user_role(role_id, conn) do
    role = Flight.Repo.get(Role, role_id)

    case role.slug do
      role_slug when role_slug in ["admin", "dispatcher"] ->
        if user_can?(conn.assigns.current_user, modify_admin_permission()) do
          role
        else
          Role.student()
        end

      _ ->
        role
    end
  end

  defp modify_admin_permission() do
    [Permission.new(:admins, :modify, :all)]
  end
end
