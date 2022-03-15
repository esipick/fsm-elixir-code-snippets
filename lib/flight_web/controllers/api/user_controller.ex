defmodule FlightWeb.API.UserController do
  use FlightWeb, :controller

  alias Flight.Accounts
  alias Flight.Accounts.Role
  alias Flight.Auth.Permission
  alias FlightWeb.StripeHelper
  alias Fsm.Billing

  import Flight.Auth.Authorization

  require ExImageInfo
  require Logger

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

  def index(conn, %{"invoice_payee" => _}) do
    users = Flight.Queries.User.get_users_by_roles(["instructor", "student","renter", "mechanic"], conn)

    render(conn, "autocomplete.json", users: users)
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
           params["aircrafts"],
           params["instructors"],
           !!params["stripe_token"],
           params["stripe_token"]
         ) do
      {:ok, user} ->
        user =
          user
          |> FlightWeb.API.UserView.show_preload()

        render(conn, "show.json", user: user)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})

      {:error, %Stripe.Error{} = error} ->
        conn
        |> put_status(error.extra.http_status)
        |> json(%{stripe_error: StripeHelper.human_error(error.message)})
    end
  end

  def change_password(conn, %{"data" => data_params}) do
    user = conn.assigns.current_user

    case Accounts.update_password(user, data_params) do
      {:ok, _user} ->
        user =
          user
          |> FlightWeb.API.UserView.show_preload()

        render(conn, "show.json", user: user)

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def update(conn, %{"data" => data_params}) do
    result =
      Accounts.api_update_user_profile(
        conn.assigns.user,
        data_params,
        data_params["aircrafts"],
        data_params["flyer_certificates"],
        data_params["instructors"]
      )

    case result do
      {:ok, user} ->
        user =
          user
          |> FlightWeb.API.UserView.show_preload(force: true)

        render(conn, "show.json", user: user)

      {:error, changeset} ->
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

  def get_students(conn, _params) do
    users = Flight.Accounts.users_with_roles([Role.student(), Role.renter()], conn)
    render(conn, "autocomplete.json", users: users)
  end

  def zip_code(conn, params) do
    Map.get(params, "id")
    |> Flight.KnowledgeBase.get_zipcode
    |> case do
      nil ->
        conn
        |> put_status(404)
        |> json(%{human_errors: ["Zip code not found."]})

      zip_code -> json(conn, Map.take(zip_code, [:zip_code, :state, :state_abbrv, :city]))
    end
  end

  defp authorize_modify(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:users, :modify, {:personal, conn.assigns.user}),
      Permission.new(:users, :modify, :all)
    ])
  end

  defp authorize_view(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:users, :view, {:personal, conn.assigns.user}),
      Permission.new(:users, :view, :all)
    ])
  end

  defp authorize_view_all(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:users, :view, :all)])
  end

  defp authorize_create(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:users, :create, :all)])
  end

  defp get_user(conn, _) do
    assign(
      conn,
      :user,
      Accounts.get_user(conn.params["id"] || conn.params["user_id"], conn)
      |> Flight.Repo.preload([:school])
    )
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

  def add_funds(conn, %{"amount" => amount, "description" => description}) do
    current_user = conn.assigns.current_user
    res = charge_user_cc(current_user, amount, description)
    case res do
      {:ok, :success} ->
        conn
        |> put_status(200)
        |> json(%{success: "Funds added successfully"})

      {:error, error_message } ->
        conn
        |> put_status(400)
        |> json(%{error: error_message})

      _ ->
        conn
        |> put_status(400)
        |> json(%{error: "Unable to Add Funds. Please contact School Admin."})
    end

  end

  def charge_user_cc(current_user, amount, description) do
    requested_user_id = current_user.id
    id = current_user.id
    school_id = current_user.school_id
    if Map.get(current_user, :stripe_customer_id) not in [nil, "", " "] do
      Stripe.Customer.retrieve(current_user.stripe_customer_id)
      |> case do
          {:ok,
            %Stripe.Customer{sources: %Stripe.List{data: [%Stripe.Card{id: stripe_customer, exp_month: exp_month, exp_year: exp_year} =card | _]},
            default_source: source_id}
          } ->
            with {:ok, parsed_amount} <- Billing.parse_amount(amount),
                  {:ok, expiry_date} <- Date.new(exp_year, exp_month, 28),
                  true <- Date.diff(expiry_date, Date.utc_today()) > 0
              do

              with acc_id <- Map.get(Billing.get_stripe_account_by_school_id(school_id), :stripe_account_id),
                    true <- acc_id != nil do

              token_result =
                if current_user do
                  token =
                    Stripe.Token.create(
                      %{customer: current_user.stripe_customer_id, card: source_id},
                      connect_account: acc_id
                    )

                  case token do
                    {:ok, token} -> {:ok, token.id}
                    error -> error
                  end
                else
                  {:ok, source_id}
                end
            resp =
              case token_result do
                {:ok, token_id} ->
                  Stripe.Charge.create(
                    %{
                      source: token_id,
                      #application_fee: application_fee_for_total(parsed_amount),
                      currency: "usd",
                      receipt_email: current_user.email,
                      amount: parsed_amount
                    },
                    connect_account: acc_id
                  )

                error ->
                  error
              end

              resp
                |> case do
                    {:ok, %Stripe.Charge{status: "succeeded"}=resp} ->
                      Billing.add_funds(%{user_id: id}, %{
                        amount: amount,
                        description: description,
                        user_id: requested_user_id
                      })

                    {:error, %Stripe.Error{extra: %{message: message, param: param}}} ->
                      {:error, "Stripe Error in parameter '#{param}': #{message}"}

                    {:error, %Stripe.Error{extra: %{raw_error: %{"message" => message, "param" => param}}}} ->
                      {:error, "Stripe Error in parameter '#{param}': #{message}"}

                    {:error, %Stripe.Error{extra: %{message: message}}} ->
                      {:error, "Stripe Error: #{message}"}

                    {:error, %Stripe.Error{message: message}} ->
                      {:error, "Stripe Error: #{message}"}

                    {:error, error} ->
                      {:error, "Stripe Raw Error: #{error}"}


                    error ->
                    Logger.info fn -> "Stripe Charge Error: #{inspect error}" end
                      {:error, "Something went wrong! Unable to add funds using card in user profile. Please update another card in profile or check amount and try again"}
                    end

              else
                nil -> {:error, "Stripe Account not added for this school."}
                error ->
                  Logger.info fn -> "Stripe Account for school Error: #{inspect error}" end
                  error
              end

            else
            resp ->
                if !resp do
                    {:error, "Card Expired! Please attach valid card in user profile"}
                else
                    {:error, "Please attach valid amount to add funds"}
                end

            end
          error ->
            Logger.info fn -> "Stripe Error: #{inspect error}" end

            {:error, "Please attach valid card in user profile"}
        end
    else
      {:error, "Invalid user's stripe customer id"}
    end
  end
end
