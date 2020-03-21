defmodule FlightWeb.API.TransactionController do
  use FlightWeb, :controller

  alias FlightWeb.API.{DetailedTransactionForm, CustomTransactionForm, TransactionView}
  alias Flight.Billing
  alias FlightWeb.ViewHelpers

  alias Flight.Auth.Permission

  plug(:get_transaction when action in [:approve, :show])
  plug(:authorize_approve when action in [:approve])
  plug(:authorize_create when action in [:create])
  plug(:authorize_view when action in [:index, :show])

  def create(conn, %{"detailed" => detailed_params}) do
    changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, detailed_params)

    with {:ok, form} <- Ecto.Changeset.apply_action(changeset, :insert),
         {:ok, transaction} <- Flight.Billing.create_transaction_from_detailed_form(form, conn) do
      transaction =
        Flight.Repo.preload(transaction, [:line_items, :user, :creator_user], force: true)

      conn
      |> put_status(201)
      |> render("show.json", transaction: transaction)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})

      {:error, %Stripe.Error{user_message: message} = error} ->
        # If this gets annoying, check if user_message is nil before sending to filter out
        # user error vs. programmer error.
        Appsignal.Transaction.set_error(
          "StripeError",
          "Error charging card, sent user message: #{inspect(error)}",
          System.stacktrace()
        )

        conn
        |> put_status(400)
        |> json(%{
          human_errors: [
            message ||
              "There was an error when charging the credit card. App developers have been notified.",
            "Do not attempt charging again if this was a student or renter, a pending transaction is waiting for the renter to approve."
          ]
        })

      {:error, error} ->
        Appsignal.Transaction.set_error(
          "ChargeError",
          "Error charging card: #{inspect(error)}",
          System.stacktrace()
        )

        IO.inspect(error)

        conn
        |> put_status(400)
        |> json(%{
          human_errors: [
            "An unknown error occurred, we're looking into it! Try again or ask an Admin for help."
          ]
        })
    end
  end

  def create(conn, %{"custom" => custom_params}) do
    changeset = CustomTransactionForm.changeset(%CustomTransactionForm{}, custom_params)

    with {:ok, form} <- Ecto.Changeset.apply_action(changeset, :insert),
         {:ok, transaction} <- Flight.Billing.create_transaction_from_custom_form(form, conn) do
      transaction =
        Flight.Repo.preload(transaction, [:line_items, :user, :creator_user], force: true)

      conn
      |> put_status(201)
      |> render("show.json", transaction: transaction)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})

      {:error, error} ->
        Appsignal.Transaction.set_error(
          "ChargeError",
          "Error charging card: #{inspect(error)}",
          System.stacktrace()
        )

        conn
        |> put_status(400)
        |> json(%{
          human_errors: [
            "An unknown error occurred, we're looking into it! Try again or ask an Admin for help."
          ]
        })
    end
  end

  def create(conn, %{
        "add_funds" => %{"user_id" => user_id, "amount" => amount, "source" => source}
      }) do
    user = Flight.Accounts.get_user(user_id, conn)

    with %Flight.Accounts.User{} <- user,
         {:ok, {_user, transaction}} <-
           Flight.Billing.add_funds_by_charge(user, conn.assigns.current_user, amount, source) do
      Flight.Billing.approve_transactions_within_balance(user)

      conn
      |> put_status(201)
      |> render("show.json", transaction: render_preloads(transaction))
    else
      error ->
        IO.inspect(error)

        conn
        |> put_status(400)
        |> json(%{human_errors: ["Unable to add funds."]})
    end
  end

  def preview(conn, %{"detailed" => detailed_params}) do
    changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, detailed_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, form} ->
        {transaction, instructor_line_item, _, aircraft_line_item, _} =
          FlightWeb.API.DetailedTransactionForm.to_transaction(
            form,
            Billing.rate_type_for_form(form, conn),
            conn
          )

        conn
        |> put_status(200)
        |> render(
          "preview.json",
          transaction: transaction,
          line_items: [instructor_line_item, aircraft_line_item] |> Enum.filter(& &1)
        )

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{error: "Invalid form", errors: ViewHelpers.translate_errors(changeset)})
    end
  end

  def preview(conn, %{"custom" => detailed_params}) do
    changeset = CustomTransactionForm.changeset(%CustomTransactionForm{}, detailed_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, form} ->
        {transaction, line_item} =
          FlightWeb.API.CustomTransactionForm.to_transaction(
            form,
            conn
          )

        conn
        |> put_status(200)
        |> render(
          "preview.json",
          transaction: transaction,
          line_items: [line_item]
        )

      {:error, _changeset} ->
        conn
        |> put_status(400)
        |> json(%{error: "Invalid form"})
    end
  end

  def index(conn, params) do
    transactions =
      params
      |> Billing.get_filtered_transactions(conn)
      |> TransactionView.preload()

    render(conn, "index.json", transactions: transactions)
  end

  def show(conn, _params) do
    transaction =
      conn.assigns.transaction
      |> TransactionView.preload()

    render(conn, "show.json", transaction: transaction)
  end

  def ephemeral_keys(conn, %{"api_version" => api_version}) do
    case Billing.create_ephemeral_key(
           conn.assigns.current_user,
           api_version
         ) do
      {:ok, key} ->
        json(conn, key)

      {:error, error} ->
        IO.inspect(error)

        conn
        |> put_status(400)
        |> json(%{error: "Error contacting stripe"})
    end
  end

  def approve(conn, params) do
    case Billing.approve_transaction(conn.assigns.transaction, params["source"]) do
      {:ok, transaction} ->
        render(conn, "show.json", transaction: render_preloads(transaction))

      {:error, %Stripe.Error{user_message: user_message}} ->
        render_approval_error(
          conn,
          user_message || "An unknown error occurred, please try again."
        )

      {:error, :must_provide_source} ->
        render_approval_error(conn, "Must provide a source.")

      {:error, :cannot_approve_non_pending_transaction} ->
        render_approval_error(
          conn,
          "This transaction has cannot be approved because it's already completed or been canceled."
        )

      {:error, %Ecto.Changeset{}} ->
        render_approval_error(
          conn,
          "Internal error occurred. Please contact your school admin if the problem persists."
        )
    end
  end

  def preferred_payment_method(conn, %{"amount" => amount}) do
    method = Billing.get_payment_method(conn.assigns.current_user, amount)
    render(conn, "preferred_payment_method.json", method: method)
  end

  ###
  # Helpers
  ###

  def render_approval_error(conn, message) do
    conn
    |> put_status(500)
    |> json(%{
      human_errors: message || "An unknown error occurred, please try again."
    })
  end

  def render_preloads(transaction_or_transactions) do
    transaction_or_transactions
    |> Flight.Repo.preload([:line_items, :user, :creator_user])
  end

  def authorize_view(conn, _) do
    permissions =
      case conn.params do
        %{"id" => _id} ->
          [
            Permission.new(:transaction, :view, {:personal, conn.assigns.transaction.user_id}),
            Permission.new(
              :transaction,
              :view,
              {:personal, conn.assigns.transaction.creator_user_id}
            )
          ]

        %{"user_id" => user_id} ->
          [Permission.new(:transaction_user, :view, {:personal, user_id})]

        %{"creator_user_id" => user_id} ->
          [Permission.new(:transaction_creator, :view, {:personal, user_id})]

        _ ->
          []
      end

    conn
    |> halt_unless_user_can?(
      [
        Permission.new(:transaction_user, :view, :all),
        Permission.new(:transaction_creator, :view, :all)
      ] ++ permissions
    )
  end

  def get_transaction(conn, _) do
    transaction =
      Billing.get_transaction(conn.params["id"] || conn.params["transaction_id"], conn)

    if transaction do
      assign(conn, :transaction, transaction |> Flight.Repo.preload([:user]))
    else
      conn
      |> resp(401, "")
    end
  end

  def authorize_approve(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:transaction_approve, :modify, {:personal, conn.assigns.transaction.user_id})
    ])
  end

  def authorize_create(conn, _) do
    permissions =
      case conn.params do
        %{
          "detailed" => %{
            "user_id" => user_id,
            "source" => "cash"
          }
        } ->
          if conn.assigns.current_user == user_id do
            [Permission.new(:transaction_cash_self, :modify, :all)]
          else
            [Permission.new(:transaction_cash, :modify, :all)]
          end

        %{
          "custom" => %{
            "user_id" => user_id,
            "source" => "cash"
          }
        } ->
          if conn.assigns.current_user == user_id do
            [Permission.new(:transaction_cash_self, :modify, :all)]
          else
            [Permission.new(:transaction_cash, :modify, :all)]
          end

        %{"detailed" => %{"creator_user_id" => creator_user_id, "user_id" => user_id}} ->
          perms = [Permission.new(:transaction_creator, :modify, {:personal, user_id})]

          if creator_user_id != user_id do
            [Permission.new(:transaction, :request, :all) | perms]
          else
            perms
          end

        %{"detailed" => %{"custom_user" => _}} ->
          [Permission.new(:transaction, :request, :all)]

        %{"custom" => %{"creator_user_id" => creator_user_id, "user_id" => user_id}} ->
          perms = [Permission.new(:transaction_creator, :modify, {:personal, user_id})]

          if creator_user_id != user_id do
            [Permission.new(:transaction, :request, :all) | perms]
          else
            perms
          end

        %{"custom" => %{"custom_user" => _}} ->
          [Permission.new(:transaction, :request, :all)]

        %{"add_funds" => %{"user_id" => user_id}} ->
          [Permission.new(:transaction_creator, :modify, {:personal, user_id})]

        _ ->
          []
      end

    conn
    |> halt_unless_user_can?([Permission.new(:transaction_creator, :modify, :all) | permissions])
  end
end
