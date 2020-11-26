defmodule Fsm.Billing.BillingQueries do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Fsm.Billing.Transaction
  alias Fsm.SchoolScope
  alias Fsm.Accounts.User
  alias Fsm.Billing.Invoice
  alias Fsm.Role
  alias Fsm.Accounts.AccountsQueries
  alias Fsm.Billing.TransactionLineItem

  require Logger

  def list_bills_query() do
    from(i in Invoice,
      left_join: t in Transaction,
      on: i.id == t.invoice_id,
      left_join: u in User,
      on: i.user_id == u.id,
      select: %{
        id: i.id,
        date: i.date,
        total: i.total,
        tax_rate: i.tax_rate,
        total_tax: i.total_tax,
        total_amount_due: i.total_amount_due,
        status: i.status,
        payment_option: i.payment_option,
        payer_name: i.payer_name,
        demo: i.demo,
        archived: i.archived,
        is_visible: i.is_visible,
        archived_at: i.archived_at,
        appointment_updated_at: i.appointment_updated_at,
        appointment_id: i.appointment_id,
        # aircraft_info: i.aircraft_info,
        session_id: i.session_id,
        inserted_at: i.inserted_at,
        transactions:
          fragment(
            "array_agg(json_build_object('id', ?, 'total', ?, 'paid_by_balance', ?, 'paid_by_charge', ?, 'stripe_charge_id', ?, 'state', ?, 'creator_user_id', ?, 'completed_at', ?, 'type', ?, 'first_name', ?, 'last_name', ?, 'email', ?, 'paid_by_cash', ?, 'paid_by_check', ?, 'paid_by_venmo', ?, 'payment_option', ?))",
            t.id,
            t.total,
            t.paid_by_balance,
            t.paid_by_charge,
            t.stripe_charge_id,
            t.state,
            t.creator_user_id,
            t.completed_at,
            t.type,
            t.first_name,
            t.last_name,
            t.email,
            t.paid_by_cash,
            t.paid_by_check,
            t.paid_by_venmo,
            t.payment_option
          ),
        user: u
      },
      group_by: [i.id, u.id],
      where: i.archived == false
    )
  end

  def list_bills_query(user_id) do
    from(i in Invoice,
      inner_join: t in Transaction,
      on: i.id == t.invoice_id,
      inner_join: u in User,
      on: i.user_id == u.id,
      select: %{
        id: i.id,
        date: i.date,
        total: i.total,
        tax_rate: i.tax_rate,
        total_tax: i.total_tax,
        total_amount_due: i.total_amount_due,
        status: i.status,
        payment_option: i.payment_option,
        payer_name: i.payer_name,
        demo: i.demo,
        archived: i.archived,
        is_visible: i.is_visible,
        archived_at: i.archived_at,
        appointment_updated_at: i.appointment_updated_at,
        inserted_at: i.inserted_at,
        # aircraft_info: i.aircraft_info,
        session_id: i.session_id,
        transactions:
          fragment(
            "array_agg(json_build_object('id', ?, 'total', ?, 'paid_by_balance', ?, 'paid_by_charge', ?, 'stripe_charge_id', ?, 'state', ?, 'creator_user_id', ?, 'completed_at', ?, 'type', ?, 'first_name', ?, 'last_name', ?, 'email', ?, 'paid_by_cash', ?, 'paid_by_check', ?, 'paid_by_venmo', ?, 'payment_option', ?))",
            t.id,
            t.total,
            t.paid_by_balance,
            t.paid_by_charge,
            t.stripe_charge_id,
            t.state,
            t.creator_user_id,
            t.completed_at,
            t.type,
            t.first_name,
            t.last_name,
            t.email,
            t.paid_by_cash,
            t.paid_by_check,
            t.paid_by_venmo,
            t.payment_option
          ),
        user: u
      },
      group_by: [i.id, u.id],
      where: i.user_id == ^user_id
    )
  end

  def list_bills_query(nil, page, per_page, sort_field, sort_order, filter, school_context) do
    list_bills_query()
    |> SchoolScope.scope_query(school_context)
    |> sort_by(sort_field, sort_order)
    |> filter(filter)
    # |> search(filter)
    |> paginate(page, per_page)
  end

  def list_bills_query(
        user_id,
        page,
        per_page,
        sort_field,
        sort_order,
        filter,
        school_context
      ) do
    list_bills_query(user_id)
    |> SchoolScope.scope_query(school_context)
    |> filter(filter)
    |> paginate(page, per_page)
  end

  defp sort_by(query, nil, nil) do
    query
  end

  defp sort_by(query, sort_field, sort_order) do
    from(g in query,
      order_by: [{^sort_order, field(g, ^sort_field)}]
    )
  end

  defp filter(query, nil) do
    query
  end

  defp filter(query, filter) do
    Logger.debug("filter: #{inspect(filter)}")

    Enum.reduce(filter, query, fn {key, value}, query ->
      case key do
        :appointment_id ->
          from(g in query,
            where: g.appointment_id == ^value
          )

        :id ->
          from(g in query,
            where: g.id == ^value
          )

        _ ->
          query
      end
    end)
  end

  def search(query, %{search_criteria: _, search_term: ""}) do
    query
  end

  def search(query, %{search_criteria: search_criteria, search_term: search_term}) do
    case search_criteria do
      :first_name ->
        from(s in query,
          where: ilike(s.first_name, ^"%#{search_term}%")
        )

      :last_name ->
        from(s in query,
          where: ilike(s.last_name, ^"%#{search_term}%")
        )

      _ ->
        query
    end
  end

  def search(query, _) do
    query
  end

  def paginate(query, 0, 0) do
    query
  end

  def paginate(query, 0, size) do
    from(query,
      limit: ^size
    )
  end

  def paginate(query, page, size) do
    from(query,
      limit: ^size,
      offset: ^((page - 1) * size)
    )
  end
end
