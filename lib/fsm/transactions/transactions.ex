defmodule Fsm.Transactions do
    import Ecto.Query, warn: false
  
    alias Flight.Repo
    alias Fsm.Transactions.TransactionsQueries
    require Logger
  
    def get_transactions(user_id, page, per_page, sort_field, sort_order, filter, context) do
        TransactionsQueries.list_transactions_query(user_id, page, per_page, sort_field, sort_order, filter, context)
        |> Repo.all
        |> case do
            nil ->
                {:ok, nil}
            data ->
                {:ok, data}
        end
    end  
  end
  