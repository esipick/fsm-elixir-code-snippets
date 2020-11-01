defmodule Fsm.Transactions.TransactionsQueries do
    @moduledoc false
  
    import Ecto.Query, warn: false
  
    alias Fsm.Transaction
  
    def all_transactions_query() do
      from t in Transaction,
      select: t
    end

    def transactions_by_user_id(user_id) do
      from t in Transaction,
      select: t,
      where: t.user_id == ^user_id
    end
  end