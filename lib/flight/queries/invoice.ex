defmodule Flight.Queries.Invoice do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Flight.Billing.{Invoice, InvoiceLineItem}

  import Pipe

  alias Flight.SchoolScope
  alias Flight.Search.Utils

  @format_str "{0M}-{0D}-{YYYY}"

  def page(school_context, page_params, params = %{}) do
    search_term = Map.get(params, "search", nil)
    user_ids = users_search(search_term, school_context)
    invoice_ids = line_items_search(search_term)

    normalized_term = Utils.normalize(search_term || "")

    start_date = parse_date(params["start_date"], 0)
    end_date = parse_date(params["end_date"], 1)

    from(i in Invoice, order_by: [desc: i.inserted_at])
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(
      search_term,
      &where(&1, [t], t.user_id in ^user_ids or t.id in ^invoice_ids or fragment(
        "to_tsvector('english', payer_name) @@ to_tsquery(?)",
        ^Utils.prefix_search(normalized_term)
      ))
    ) |> pass_unless(start_date, &where(&1, [t], t.inserted_at >= ^start_date))
    |> pass_unless(end_date, &where(&1, [t], t.inserted_at <= ^end_date))
    |> pass_unless(params["status"], &where(&1, [t], t.status == ^parse_status(params["status"])))
    |> Repo.paginate(page_params)
  end

  def own_invoices(school_context, page_params, params) do
    from(i in Invoice, order_by: [desc: i.inserted_at])
    |> SchoolScope.scope_query(school_context)
    |> where([i], i.user_id == ^params[:user_id])
    |> Repo.paginate(page_params)
  end

  defp parse_date(date, shift_days) do
    case date do
      date when date in [nil, ""] -> nil
      _ ->
        date
        |> Timex.parse!(@format_str)
        |> Timex.to_naive_datetime()
        |> Timex.shift(days: shift_days)
    end
  end

  defp users_search(search_term, school_context) do
    case search_term do
      nil -> []
      _ -> Flight.Queries.User.search_users_ids_by_name(search_term, school_context)
    end
  end

  defp line_items_search(search_term) do
    case search_term do
      nil -> []
      _ ->
        from(
          i in InvoiceLineItem,
          join: a in assoc(i, :aircraft),
          select: %{invoice_id: i.invoice_id}
        )
        |> Flight.Scheduling.Search.Aircraft.run(search_term)
        |> Repo.all
        |> Enum.map(fn i -> i.invoice_id end)
    end
  end

  defp parse_status(param) do
    case Integer.parse(param) do
      {num, _} -> num
      :error -> nil
    end
  end
end
