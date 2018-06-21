defmodule FlightWeb.API.TransactionController do
  use FlightWeb, :controller

  alias FlightWeb.API.DetailedTransactionForm
  alias Flight.Billing

  alias Flight.Auth.Permission

  plug(:get_transaction when action in [:approve])
  plug(:authorize_approve when action in [:approve])
  plug(:authorize_create when action in [:create])
  plug(:authorize_view when action in [:index])

  def create(conn, %{"detailed" => detailed_params}) do
    changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, detailed_params)

    with {:ok, form} <- Ecto.Changeset.apply_action(changeset, :insert),
         {:ok, transaction} <- Flight.Billing.create_transaction_from_detailed_form(form) do
      transaction = Flight.Repo.preload(transaction, [:line_items, :user, :creator_user])

      conn
      |> put_status(201)
      |> render("show.json", transaction: transaction)
    else
      {:error, error} ->
        IO.inspect(error)

        conn
        |> put_status(400)
        |> json(%{errors: "blah"})
    end
  end

  def create(conn, %{
        "add_funds" => %{"user_id" => user_id, "amount" => amount, "source" => source}
      }) do
    user = Flight.Accounts.get_user(user_id)

    with {:ok, {_user, transaction}} <-
           Flight.Billing.add_funds_by_charge(user, conn.assigns.current_user, amount, source) do
      conn
      |> put_status(201)
      |> render("show.json", transaction: render_preloads(transaction))
    else
      {:error, error} ->
        IO.inspect(error)

        conn
        |> put_status(400)
        |> json(%{errors: "blah"})
    end
  end

  def preview(conn, %{"detailed" => detailed_params}) do
    changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, detailed_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, form} ->
        {transaction, instructor_line_item, aircraft_line_item, _} =
          FlightWeb.API.DetailedTransactionForm.to_transaction(form)

        conn
        |> put_status(200)
        |> render(
          "preview.json",
          transaction: transaction,
          instructor_line_item: instructor_line_item,
          aircraft_line_item: aircraft_line_item
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
      |> Billing.get_filtered_transactions()
      |> Flight.Repo.preload([:line_items, :user, :creator_user])

    render(conn, "index.json", transactions: transactions)
  end

  def ephemeral_keys(conn, %{"api_version" => api_version}) do
    case Billing.create_ephemeral_key(conn.assigns.current_user.stripe_customer_id, api_version) do
      {:ok, key} ->
        json(conn, key)

      {:error, _error} ->
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
    method = Billing.preferred_payment_method(conn.assigns.current_user, amount)
    render(conn, "preferred_payment_method.json", method: method)
  end

  ###
  # Helpers
  ###

  def render_approval_error(conn, message) do
    conn
    |> put_status(500)
    |> json(%{
      error_message: message || "An unknown error occurred, please try again."
    })
  end

  def render_preloads(transaction_or_transactions) do
    transaction_or_transactions
    |> Flight.Repo.preload([:line_items, :user, :creator_user])
  end

  def authorize_view(conn, _) do
    permissions =
      case conn.params do
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
    transaction = Billing.get_transaction(conn.params["id"] || conn.params["transaction_id"])

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
        %{"detailed" => %{"user_id" => user_id}} ->
          [Permission.new(:transaction_creator, :modify, {:personal, user_id})]

        %{"add_funds" => %{"user_id" => user_id}} ->
          [Permission.new(:transaction_creator, :modify, {:personal, user_id})]

        _ ->
          []
      end

    conn
    |> halt_unless_user_can?([Permission.new(:transaction_creator, :modify, :all)] ++ permissions)
  end
end