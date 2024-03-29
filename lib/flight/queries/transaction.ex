defmodule Flight.Queries.Transaction do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Flight.Billing.{Transaction, TransactionLineItem, InvoiceLineItem}

  import Pipe

  alias Flight.SchoolScope
  alias Flight.Search.Utils

  @format_str "{0M}-{0D}-{YYYY}"

  def page(%{assigns: %{current_user: _current_user}} = school_context, page_params, params = %{}) do
    search_term = Map.get(params, "search", nil)
    user_ids = users_search(search_term, school_context)
    transaction_ids = transaction_line_items_search(search_term)
    invoice_ids = invoice_line_items_search(search_term)

    normalized_term = Utils.normalize(search_term || "")

    start_date = parse_date(params["start_date"], 0)
    end_date = parse_date(params["end_date"], 1)
    state = parse_state(params["state"])

    from(i in Transaction, order_by: [desc: i.inserted_at])
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(
      search_term,
      &where(
        &1,
        [t],
        t.user_id in ^user_ids or t.id in ^transaction_ids or t.invoice_id in ^invoice_ids or
          fragment(
            "to_tsvector('english', first_name) @@ to_tsquery(?)",
            ^Utils.prefix_search(normalized_term)
          )
      )
    )
    |> pass_unless(start_date, &where(&1, [t], t.inserted_at >= ^start_date))
    |> pass_unless(end_date, &where(&1, [t], t.inserted_at <= ^end_date))
    |> pass_unless(state, &where(&1, [t], t.state == ^state))
    |> Repo.paginate(page_params)
  end

  def own_transactions(%{assigns: %{current_user: %{id: user_id}}} = school_context, page_params, params = %{}) do
    search_term = Map.get(params, "search", nil)
    user_ids = users_search(search_term, school_context)
    transaction_ids = transaction_line_items_search(search_term)
    invoice_ids = invoice_line_items_search(search_term)

    normalized_term = Utils.normalize(search_term || "")

    start_date = parse_date(params["start_date"], 0)
    end_date = parse_date(params["end_date"], 1)
    state = parse_state(params["state"])

    from(i in Transaction,  where: i.user_id == ^user_id, order_by: [desc: i.inserted_at])
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(
      search_term,
      &where(
        &1,
        [t],
        t.user_id in ^user_ids or t.id in ^transaction_ids or t.invoice_id in ^invoice_ids or
          fragment(
            "to_tsvector('english', first_name) @@ to_tsquery(?)",
            ^Utils.prefix_search(normalized_term)
          )
      )
    )
    |> pass_unless(start_date, &where(&1, [t], t.inserted_at >= ^start_date))
    |> pass_unless(end_date, &where(&1, [t], t.inserted_at <= ^end_date))
    |> pass_unless(state, &where(&1, [t], t.state == ^state))
    |> Repo.paginate(page_params)
  end

  def get_invoice_transaction(invoice_id) do
    from(t in Transaction, where: t.invoice_id == ^invoice_id, limit: 1)
    |> Repo.one([])
  end

  def get_bulk_invoice_transaction(bulk_invoice_id) do
    from(t in Transaction, where: t.bulk_invoice_id == ^bulk_invoice_id, limit: 1)
    |> Repo.one([])
  end

  defp parse_date(date, shift_days) do
    case date do
      date when date in [nil, ""] ->
        nil

      _ ->
        date
        |> Timex.parse!(@format_str)
        |> Timex.to_naive_datetime()
        |> Timex.shift(days: shift_days)
    end
  end

  defp parse_state(param) do
    case param do
      param when param in ["pending", "completed", "canceled", "failed"] ->
        param

      _ ->
        nil
    end
  end

  defp users_search(search_term, school_context) do
    case search_term do
      nil -> []
      _ -> Flight.Queries.User.search_users_ids_by_name(search_term, school_context)
    end
  end

  defp transaction_line_items_search(search_term) do
    case search_term do
      nil ->
        []

      _ ->
        from(
          i in TransactionLineItem,
          join: a in assoc(i, :aircraft),
          select: %{transaction_id: i.transaction_id}
        )
        |> Flight.Scheduling.Search.Aircraft.run(search_term)
        |> Repo.all()
        |> Enum.map(fn i -> i.transaction_id end)
    end
  end

  defp invoice_line_items_search(search_term) do
    case search_term do
      nil ->
        []

      _ ->
        from(
          i in InvoiceLineItem,
          join: aircraft in assoc(i, :aircraft),
          join: invoice in assoc(i, :invoice),
          where: invoice.archived == false,
          select: %{invoice_id: i.invoice_id}
        )
        |> Flight.Scheduling.Search.Aircraft.run(search_term)
        |> Repo.all()
        |> Enum.map(fn i -> i.invoice_id end)
    end
  end
end
