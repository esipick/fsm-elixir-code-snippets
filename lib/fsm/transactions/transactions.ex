defmodule Fsm.Transactions do
    import Ecto.Query, warn: false
  
    alias Flight.Repo
    alias Fsm.Transactions.TransactionsQueries
    require Logger
  
    def get_all_transactions() do
        TransactionsQueries.all_transactions_query()
        |> Repo.all
        |> case do
            nil ->
                {:ok, nil}
            data ->
                {:ok, data}
        end
    end

    def get_transactions_by_user_id(user_id) do
        TransactionsQueries.transactions_by_user_id(user_id)
        |> Repo.all
        |> case do
            nil ->
                {:ok, nil}
            data ->
                {:ok, data}
        end
    end
  
  end
  