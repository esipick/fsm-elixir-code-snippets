defmodule Flight.Queries.Transaction do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Flight.Billing.Transaction

  import Pipe

  alias Flight.SchoolScope

  def page(school_context, page_params, params = %{}) do
    from(i in Transaction, order_by: [desc: i.inserted_at])
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(params["user_id"], &where(&1, [t], t.user_id == ^params["user_id"]))
    |> Repo.paginate(page_params)
  end
end
