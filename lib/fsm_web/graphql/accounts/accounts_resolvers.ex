defmodule FsmWeb.GraphQL.Accounts.AccountsResolvers do
  alias Fsm.Accounts
  alias Fsm.Accounts.User
  alias FsmWeb.GraphQL.Accounts.UserView
  alias FsmWeb.GraphQL.Log
  alias Fsm.Accounts.Role

  import Flight.Auth.Authorization
  alias Flight.Auth.Permission

  require Logger

  def login(_parent, %{email: email, password: password} = params, resolution) do
    Accounts.api_login(%{"email" => email, "password" => password})
    |> case do
         {:ok, res} -> {:ok, res}
         {:error, error} ->
           format_error(error)

         error ->
           Logger.error(fn -> "Login User Error: #{inspect(error)}" end)
           {:error, "Unable to login user"}
       end
  end

  def get_current_user(parent, _args, %{context: %{current_user: %{id: id}}} = context) do
    user = Accounts.get_user(id) |> UserView.map()
    {:ok, user}
  end

  def get_user(parent, args, %{context: %{current_user: %{id: id}}} = context) do
    user =
      Accounts.get_user(args.id)
      |> UserView.map()

    {:ok, user}
  end

  def list_users(
        parent,
        args,
        %{context: %{current_user: %{id: user_id, school_id: school_id}}} = context
      ) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}

    users = Accounts.list_users(page, per_page, sort_field, sort_order, filter, context)
      |> UserView.map()
      |> Enum.reduce([], fn (user, agg) ->
          roles = user.roles |> Enum.uniq()
          user = Map.put(user, :roles, roles)
          agg ++ [user]
        end)

    resp = {:ok, users}
    Log.response(resp, __ENV__.function, :info)
  end

  def list_instructors(
        parent,
        args,
        context
      ) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}

    users =
      Accounts.list_instructors(page, per_page, sort_field, sort_order, filter, context)
      |> UserView.map()

    resp = {:ok, users}
    Log.response(resp, __ENV__.function, :info)
  end

  def update_user(parent, args, %{context: %{current_user: current_user}} = context) do
    id = args.id

    requested_user =
      Accounts.get_user(id)
      |> UserView.map()

    user_input = Map.get(args, :user_input)
    avatar = Map.get(user_input, :avatar_binary) || Map.get(user_input, :avatar)
    user_input = Map.put(user_input, :avatar, avatar)

    # params["role_slugs"]
    role_slugs = Map.get(args, :role_slugs)

    role_slugs =
      with true <- is_list(role_slugs) do
        if user_can?(
             %User{id: current_user.id, school_id: current_user.school_id},
             modify_admin_permission()
           ) do
          role_slugs
        else
          Enum.filter(role_slugs, fn p -> p != "admin" end)
        end
      else
        "" ->
          %{}

        _ ->
          nil
      end

    role_slugs =
      if role_slugs not in ["", %{}, nil, []] do
        role_slugs
      else
        nil
      end

    resp =
      Accounts.admin_update_user_profile(requested_user, user_input, role_slugs)
      |> case do
        %User{} ->
          {:ok,
           Accounts.get_user(id)
           |> UserView.map()}

      {:error, error} ->
        Logger.error(fn -> "Update User Error: #{inspect(error)}" end)
        format_error(error)

      error ->
        Logger.error(fn -> "Update User Error: #{inspect(error)}" end)
        {:error, "Unable to update user"}
      end

    Log.response(resp, __ENV__.function, :info)

    #    tab = Map.get(user_form, "tab") || "personal"
    #
    #    user_form =
    #      if tab == :pilot do
    #        pilot_aircraft_categories =
    #          (Map.get(params, :pilot_aircraft_categories) || %{})
    #          |> Map.keys
    #        pilot_class =
    #          (Map.get(params, :pilot_class) || %{})
    #          |> Map.keys
    #        pilot_ratings =
    #          (Map.get(params, :pilot_ratings) || %{})
    #          |> Map.keys
    #        pilot_endorsements =
    #          (Map.get(params, :pilot_endorsements) || %{})
    #          |> Map.keys
    #
    #        user_form
    #        |> Map.put(:pilot_aircraft_categories, pilot_aircraft_categories)
    #        |> Map.put(:pilot_class, pilot_class)
    #        |> Map.put(:pilot_ratings, pilot_ratings)
    #        |> Map.put(:pilot_endorsements, pilot_endorsements)
    #      else
    #        user_form
    #      end
    #
    #    aircrafts =
    #      case Map.get(user_form, :aircrafts) do
    #        params when params in [nil, []] ->
    #          []
    #
    #        params when is_list(params) ->
    #          params
    #          |> Enum.reject(&(&1 in [nil, ""]))
    #          |> Enum.map(&String.to_integer(&1))
    #
    #        _ ->
    #          nil
    #      end
    #
    #    instructors =
    #      case Map.get(user_form, :instructors) do
    #        params when params in [nil, []] ->
    #          []
    #
    #        params when is_list(params) ->
    #          params
    #          |> Enum.reject(&(&1 in [nil, ""]))
    #          |> Enum.map(&String.to_integer(&1))
    #
    #        _ ->
    #          nil
    #      end

    #    role_params = Map.get(:role_slugs)
    #
    #    role_slugs =
    #      with %{} <- role_params, params <- Map.keys(role_params) do
    #        if user_can?(conn.assigns.current_user, modify_admin_permission()) do
    #          params
    #        else
    #          Enum.filter(params, fn p -> p != "admin" end)
    #        end
    #      else
    #        "" ->
    #          %{}
    #
    #        _ ->
    #          nil
    #      end

    #    certs =
    #      case params["flyer_certificate_slugs"] do
    #        %{} = params -> Map.keys(params)
    #        _ -> nil
    #      end

    #    case

    #    Accounts.admin_update_user_profile(
    #           requested_user,
    #           user_form
    ##           , nil,
    ##           nil,
    ##           nil,
    ##           nil
    #         )

    #    do
    #      {:ok, user} ->
    #        redirect(conn, to: "/admin/users/#{user.id}")

    #      {:error, changeset} ->
    #        user = conn.assigns.requested_user
    #        aircrafts = Accounts.get_aircrafts(conn)
    #        role = Accounts.role_for_slug("instructor")
    #        instructors = Queries.User.get_users_by_role(role, conn)
    #
    #        render(
    #          conn,
    #          "edit.html",
    #          aircrafts: aircrafts,
    #          changeset: changeset,
    #          instructors: instructors,
    #          skip_shool_select: true,
    #          user: user,
    #          stripe_error: nil,
    #          tab: tab
    #        )
    #    end
  end

  def change_password(_parent, params, %{context: %{current_user: %{id: user_id}}} = context) do
    current_user =
      Accounts.get_user(user_id)
      |> UserView.map()

    case Fsm.Accounts.update_password(current_user, params) do
      {:ok, _user} ->
        user =
          current_user
          |> FlightWeb.API.UserView.show_preload()

        {:ok, user}

      {:error, changeset} ->
        {:error, FsmWeb.ViewHelpers.human_error_messages(changeset)}
    end
  end

  def create_push_token(_parent, params, %{context: %{current_user: %{id: user_id}}} = context) do
    with %{resp_body: nil} <- Fsm.Accounts.authorize_modify(user_id, params.user_id) do
      Fsm.Accounts.create_push_token(params.user_id, params.token, params.platform)

    else
      _error -> {:error, "unauthorized"}
    end
  end

  def delete_push_token(_parent, params, %{context: %{current_user: %{id: user_id}}} = context) do
    with %{resp_body: nil} <- Fsm.Accounts.authorize_modify(user_id, params.user_id) do
      Fsm.Accounts.delete_push_token(params.user_id, params.token, params.platform)

    else
      _error -> {:error, "unauthorized"}
    end
  end

  defp check_user(email) do
    user = Flight.Accounts.get_user_by_email(email)

    cond do
      user && user.archived ->
        {:error, "Account is suspended. Please contact your school administrator to reinstate it."}

      user && !user.archived ->
        {:ok, reset} = Flight.Accounts.create_password_reset(user)

        reset
        |> Flight.Repo.preload(:user)
        |> Flight.Email.reset_password_email()
        |> Flight.Mailer.deliver_later()

        {:ok, "Please check your email for password reset instructions."}

      user == nil ->
        {:error, "This email is not registered"}
    end
  end

  def forgot_submit(_parent, %{email: email}, _context) do
    email = String.trim(email)
    cond do
      email == "" ->
        {:error, "Please enter your email"}

      String.match?(email, Flight.Format.email_regex()) ->
        check_user(email)

      true ->
        {:error, "Invalid email format"}
    end
  end

  def reset(_parent, %{token: token}, _context) do
    case Flight.Accounts.get_password_reset_from_token(token || "") do
      %{} = reset ->
        {:ok, reset}

      _ ->
        {:error, "The reset link you clicked is either expired or invalid. Please attempt to reset your password again by entering your email."}
    end
  end

  def reset_submit(_parent, %{token: token, password: password, password_confirmation: confirmation}, _context) do
    case Flight.Accounts.get_password_reset_from_token(token || "") do
      %{} = reset ->
        password = String.trim(password)
        confirmation = String.trim(confirmation)

        case password == confirmation do
          true ->
            Accounts.set_password(reset.user, password)

          false ->
            {:error, "Password and confirmation didn't match. Please try again."}
        end

      _ ->
        {:error, "The reset link you clicked is either expired or invalid. Please attempt to reset your password again by entering your email."}
    end
  end

  def format_error(%{human_errors: human_errors}=changeset) do
    errors = human_errors
             |> Enum.map(fn(value) ->
      [message: "#{value}"]
      end)

    {:error, errors}
  end

  def format_error(%{errors: errors} = changeset) do
    errors = errors
             |> Enum.map(fn({key, {value, context}}) ->
      details = context |> Enum.map(fn({a, b}) ->
        %{"#{a}": b}
      end)
      [message: "#{key} #{value}", details: details]
    end)
    {:error, errors}
  end

  def format_error(changeset) do
    {:error, changeset}
  end

  def create_user(parent, args, %{context: %{current_user: current_user}} = context) do
    user_input = Map.get(args, :user_input)
    data_params = Map.put(user_input, :password , Flight.Random.string(20))
    role_slug = Map.get(args, :role_slug)

    role =  fetch_user_role(role_slug, %User{id: current_user.id, school_id: current_user.school_id})


    case Accounts.CreateUserWithInvitation.run(
           data_params,
           current_user,
           role
         ) do
      {:ok, user} ->
        {:ok, user}

      {:error, error} ->
        Logger.error(fn -> "Create User Error: #{inspect(error)}" end)
        format_error(error)

      error ->
        Logger.error(fn -> "Create User Error: #{inspect(error)}" end)
        {:error, "Unable to create user"}
    end
  end

  defp fetch_user_role(role_slug, current_user) do
    role = Accounts.get_role(role_slug, :slug)

    case role.slug do
      role_slug when role_slug in ["admin", "dispatcher"] ->
        if user_can?(current_user, modify_admin_permission()) do
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
