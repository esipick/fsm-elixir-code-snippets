defmodule Flight.Queries.Invoice do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Flight.Billing.{Invoice, InvoiceLineItem}

  import Pipe

  alias Flight.SchoolScope
  alias Flight.Search.Utils

  @format_str "{0M}-{0D}-{YYYY}"

  def all(%{assigns: %{current_user: _current_user}} = school_context, params = %{}) do
    search_term = Map.get(params, "search", nil)
    user_ids = users_search(search_term, school_context)
    invoice_ids = line_items_search(search_term)

    normalized_term = Utils.normalize(search_term || "")

    start_date = parse_date(params["start_date"], 0)
    end_date = parse_date(params["end_date"], 1)
    status = params["status"] && parse_status(params["status"])

    from(i in Invoice, where: i.archived == false and i.is_visible == true, order_by: [desc: i.id])
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(
      search_term,
      &where(
        &1,
        [t],
        t.user_id in ^user_ids or t.id in ^invoice_ids or
          fragment(
            "to_tsvector('english', payer_name) @@ to_tsquery(?)",
            ^Utils.prefix_search(normalized_term)
          ) or ilike(t.payer_name, ^normalized_term)
      )
    )
    |> pass_unless(start_date, &where(&1, [t], t.inserted_at >= ^start_date))
    |> pass_unless(end_date, &where(&1, [t], t.inserted_at <= ^end_date))
    |> pass_unless(status, &where(&1, [t], t.status == ^status))
    |> pass_unless(params["user_id"], &where(&1, [t], t.user_id == ^params["user_id"]))
  end

  def own_invoices(%{assigns: %{current_user: %{id: user_id}}} = school_context, params = %{}) do
    search_term = Map.get(params, "search", nil)
    user_ids = users_search(search_term, school_context)
    invoice_ids = line_items_search(search_term)

    normalized_term = Utils.normalize(search_term || "")

    start_date = parse_date(params["start_date"], 0)
    end_date = parse_date(params["end_date"], 1)
    status = params["status"] && parse_status(params["status"])

    from(i in Invoice, where: i.archived == false and i.is_visible == true and i.user_id == ^user_id, order_by: [desc: i.id])
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(
         search_term,
         &where(
           &1,
           [t],
           t.user_id in ^user_ids or t.id in ^invoice_ids or
           fragment(
             "to_tsvector('english', payer_name) @@ to_tsquery(?)",
             ^Utils.prefix_search(normalized_term)
           )
         )
       )
    |> pass_unless(start_date, &where(&1, [t], t.inserted_at >= ^start_date))
    |> pass_unless(end_date, &where(&1, [t], t.inserted_at <= ^end_date))
    |> pass_unless(status, &where(&1, [t], t.status == ^status))
    |> pass_unless(params["user_id"], &where(&1, [t], t.user_id == ^params["user_id"]))
  end

  def course_invoices(user_id) do
    from i in Invoice,
         inner_join: li in InvoiceLineItem, on: i.id == li.invoice_id,
         select: i,
         where: i.user_id == ^user_id and i.status == 1 and li.type == 5 and not is_nil(i.course_id)  and not is_nil(li.course_id)
  end
  def course_invoices_by_course(user_id, course_id) do
    from i in Invoice,
         inner_join: li in InvoiceLineItem, on: i.id == li.invoice_id,
         select: i,
         where: i.user_id == ^user_id and i.course_id == ^course_id
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

  defp users_search(search_term, school_context) do
    case search_term do
      nil -> []
      _ -> Flight.Queries.User.search_users_ids_by_name(search_term, school_context)
    end
  end

  defp line_items_search(search_term) do
    case search_term do
      nil ->
        []

      _ ->
        from(
          i in InvoiceLineItem,
          join: a in assoc(i, :aircraft),
          select: %{invoice_id: i.invoice_id}
        )
        |> Flight.Scheduling.Search.Aircraft.run(search_term)
        |> Repo.all()
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
