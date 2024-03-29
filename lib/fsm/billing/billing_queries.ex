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
  alias Fsm.Billing.InvoiceLineItem
  alias Fsm.Aircrafts.Aircraft
  alias Fsm.SchoolAssets.Room
  alias Fsm.Scheduling.Appointment

  require Logger

  def list_bills_query() do
    from(i in Invoice,
      left_join: t in Transaction,
      on: (i.id == t.invoice_id or i.bulk_invoice_id == t.bulk_invoice_id),
      left_join: ili in InvoiceLineItem,
      on: (i.id == ili.invoice_id),
      left_join: ac in Aircraft,
      on: (ac.id == ili.aircraft_id),
      left_join: a in Appointment,
      on: (a.id == i.appointment_id),
      left_join: u in User,
      on: i.user_id == u.id,
      left_join: instructor in User,
      on: ili.instructor_user_id == instructor.id,
      select: %{
        id: i.id,
        date: i.date,
        total: i.total,
        tax_rate: i.tax_rate,
        total_tax: i.total_tax,
        total_amount_due: i.total_amount_due,
        status: i.status,
        appt_status: a.appt_status,
        payment_option: i.payment_option,
        payer_name: i.payer_name,
        demo: i.demo,
        archived: i.archived,
        is_visible: i.is_visible,
        archived_at: i.archived_at,
        appointment_updated_at: i.appointment_updated_at,
        appointment_id: i.appointment_id,
        notes: i.notes,
        payer_email: i.payer_email,

        # aircraft_info: i.aircraft_info,
        session_id: i.session_id,
        inserted_at: i.inserted_at,
        is_admin_invoice: i.is_admin_invoice,
        line_items:
          fragment(
            "array_agg(json_build_object('id', ?, 'invoice_id', ?, 'description', ?, 'rate', ?, 'quantity', ?, 'amount', ?, 'inserted_at', ?, 'updated_at', ?, 'instructor_user_id', ?, 'type', ?, 'aircraft_id', ?, 'hobbs_start', ?, 'hobbs_end', ?, 'tach_start', ?, 'tach_end', ?, 'hobbs_tach_used', ?, 'taxable', ?, 'deductible', ?, 'creator_id', ?, 'room_id', ?, 'tail_number', ?, 'make', ?, 'model', ?,'serial_number', ?, 'aircraft_simulator_name', ?, 'simulator', ?, 'instructor_name', ?, 'name', ?, 'parts_serial_number', ?, 'notes', ?))",
            ili.id,
            ili.invoice_id,
            ili.description,
            ili.rate,
            ili.quantity,
            ili.amount,
            ili.inserted_at,
            ili.updated_at,
            ili.instructor_user_id,
            ili.type,
            ili.aircraft_id,
            ili.hobbs_start,
            ili.hobbs_end,
            ili.tach_start,
            ili.tach_end,
            ili.hobbs_tach_used,
            ili.taxable,
            ili.deductible,
            ili.creator_id,
            ili.room_id,
            ac.tail_number,
            ac.make,
            ac.model,
            ac.serial_number,
            ac.name,
            ac.simulator,
            fragment("concat(?, ' ', ?)", instructor.first_name, instructor.last_name),
            ili.name,
            ili.serial_number,
            ili.notes
          ),
        transactions:
          fragment(
            "array_agg(json_build_object('id', ?, 'total', ?, 'paid_by_balance', ?, 'paid_by_charge', ?, 'stripe_charge_id', ?, 'state', ?, 'creator_user_id', ?, 'completed_at', ?, 'type', ?, 'first_name', ?, 'last_name', ?, 'email', ?, 'paid_by_cash', ?, 'paid_by_check', ?, 'paid_by_venmo', ?, 'payment_option', ?, 'inserted_at', ?))",
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
            t.payment_option,
            t.inserted_at
          ),
        user: u
      },
      group_by: [i.id, u.id, a.appt_status],
      where: i.archived == false and i.is_visible == true
    )
  end

  def list_bills_query(user_id) do
    from(i in Invoice,
      left_join: t in Transaction,
      on: (i.id == t.invoice_id or i.bulk_invoice_id == t.bulk_invoice_id),
      inner_join: ili in InvoiceLineItem,
      on: (i.id == ili.invoice_id),
      left_join: a in Appointment,
      on: (a.id == i.appointment_id),
      left_join: ac in Aircraft,
      on: (ac.id == ili.aircraft_id),
      inner_join: u in User,
      on: i.user_id == u.id,
      left_join: instructor in User,
      on: ili.instructor_user_id == instructor.id,
      select: %{
        id: i.id,
        date: i.date,
        total: i.total,
        tax_rate: i.tax_rate,
        total_tax: i.total_tax,
        total_amount_due: i.total_amount_due,
        status: i.status,
        appt_status: a.appt_status,
        payment_option: i.payment_option,
        payer_name: i.payer_name,
        demo: i.demo,
        archived: i.archived,
        is_visible: i.is_visible,
        archived_at: i.archived_at,
        appointment_updated_at: i.appointment_updated_at,
        appointment_id: i.appointment_id,
        inserted_at: i.inserted_at,
        notes: i.notes,
        payer_email: i.payer_email,
        # aircraft_info: i.aircraft_info,
        session_id: i.session_id,
        is_admin_invoice: i.is_admin_invoice,
        line_items:
          fragment(
            "array_agg(json_build_object('id', ?, 'invoice_id', ?, 'description', ?, 'rate', ?, 'quantity', ?, 'amount', ?, 'inserted_at', ?, 'updated_at', ?, 'instructor_user_id', ?, 'type', ?, 'aircraft_id', ?, 'hobbs_start', ?, 'hobbs_end', ?, 'tach_start', ?, 'tach_end', ?, 'hobbs_tach_used', ?, 'taxable', ?, 'deductible', ?, 'creator_id', ?, 'room_id', ?, 'tail_number', ?, 'make', ?, 'model', ?,'serial_number', ?, 'aircraft_simulator_name', ?, 'simulator', ?,'instructor_name', ?, 'name', ?, 'parts_serial_number', ?, 'notes', ?))",
            ili.id,
            ili.invoice_id,
            ili.description,
            ili.rate,
            ili.quantity,
            ili.amount,
            ili.inserted_at,
            ili.updated_at,
            ili.instructor_user_id,
            ili.type,
            ili.aircraft_id,
            ili.hobbs_start,
            ili.hobbs_end,
            ili.tach_start,
            ili.tach_end,
            ili.hobbs_tach_used,
            ili.taxable,
            ili.deductible,
            ili.creator_id,
            ili.room_id,
            ac.tail_number,
            ac.make,
            ac.model,
            ac.serial_number,
            ac.name,
            ac.simulator,
            fragment("concat(?, ' ', ?)", instructor.first_name, instructor.last_name),
            ili.name,
            ili.serial_number,
            ili.notes
          ),
        transactions:
          fragment(
            "array_agg(json_build_object('id', ?, 'total', ?, 'paid_by_balance', ?, 'paid_by_charge', ?, 'stripe_charge_id', ?, 'state', ?, 'creator_user_id', ?, 'completed_at', ?, 'type', ?, 'first_name', ?, 'last_name', ?, 'email', ?, 'paid_by_cash', ?, 'paid_by_check', ?, 'paid_by_venmo', ?, 'payment_option', ?, 'inserted_at', ?))",
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
            t.payment_option,
            t.inserted_at
          ),
        user: u
      },
      group_by: [i.id, u.id, a.appt_status],
      where: i.user_id == ^user_id and i.archived == false and i.is_visible == true
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

  def list_transactions_query(user_id) do
    from(t in Transaction,
      inner_join: tli in TransactionLineItem,
      on: (t.id == tli.transaction_id),
      left_join: ac in Aircraft,
      on: (ac.id == tli.aircraft_id),
      inner_join: u in User,
      on: t.user_id == u.id,
      left_join: instructor in User,
      on: tli.instructor_user_id == instructor.id,
      select: %{
        id: t.id,
        paid_by_balance: t.paid_by_balance,
        paid_by_charge: t.paid_by_charge,
        paid_by_check: t.paid_by_check,
        paid_by_venmo: t.paid_by_venmo,
        stripe_charge_id: t.stripe_charge_id,
        state: t.state,
        total: t.total,
        type: t.type,
        first_name: t.first_name,
        last_name: t.last_name,
        email: t.email,
        completed_at: t.completed_at,
        payment_option: t.payment_option,
        completed_at: t.completed_at,
        error_message: t.error_message,
        creator_user_id: t.creator_user_id,
        inserted_at: t.inserted_at,

        line_items: fragment(
          "array_agg(json_build_object('id', ?, 'amount', ?, 'description', ?, 'aircraft_id', ?, 'instructor_user_id', ?, 'type', ?, 'total_tax', ?))",
          tli.id,
          tli.amount,
          tli.description,
          tli.aircraft_id,
          tli.instructor_user_id,
          tli.type,
          tli.total_tax
        ),
      },
      group_by: [t.id, u.id],
      where: t.user_id == ^user_id and (is_nil(t.invoice_id) or is_nil(t.bulk_invoice_id))
    )
  end

  def list_transactions_query() do
    from(t in Transaction,
      inner_join: tli in TransactionLineItem,
      on: (t.id == tli.transaction_id),
      left_join: ac in Aircraft,
      on: (ac.id == tli.aircraft_id),
      inner_join: u in User,
      on: t.user_id == u.id,
      left_join: instructor in User,
      on: tli.instructor_user_id == instructor.id,
      select: %{
        id: t.id,
        paid_by_balance: t.paid_by_balance,
        paid_by_charge: t.paid_by_charge,
        paid_by_check: t.paid_by_check,
        paid_by_venmo: t.paid_by_venmo,
        stripe_charge_id: t.stripe_charge_id,
        state: t.state,
        total: t.total,
        type: t.type,
        first_name: t.first_name,
        last_name: t.last_name,
        email: t.email,
        completed_at: t.completed_at,
        payment_option: t.payment_option,
        completed_at: t.completed_at,
        error_message: t.error_message,
        creator_user_id: t.creator_user_id,
        inserted_at: t.inserted_at,
        line_items: fragment(
          "array_agg(json_build_object('id', ?, 'amount', ?, 'description', ?, 'aircraft_id', ?, 'instructor_user_id', ?, 'type', ?, 'total_tax', ?))",
          tli.id,
          tli.amount,
          tli.description,
          tli.aircraft_id,
          tli.instructor_user_id,
          tli.type,
          tli.total_tax
        ),
      },
      group_by: [t.id, u.id],
      where: is_nil(t.invoice_id) or is_nil(t.bulk_invoice_id)
    )
  end

  def list_transactions_query(nil, page, per_page, school_context) do
    list_transactions_query()
     |> SchoolScope.scope_query(school_context)
     |> sort_by(:inserted_at, :desc)
     |> paginate(page, per_page)
  end

  def list_transactions_query(user_id, page, per_page, school_context) do
    list_transactions_query(user_id)
     |> SchoolScope.scope_query(school_context)
     |> sort_by(:inserted_at, :desc)
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
    |> sort_by(sort_field, sort_order)
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
