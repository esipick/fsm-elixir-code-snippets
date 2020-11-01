defmodule FsmWeb.GraphQL.Transactions.TransactionsResolvers do
    alias Fsm.Transactions
    require Logger

    def get_all_transactions(parent, args, %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}}=context) do 
        if "admin" in roles or "dispatcher" in roles do
            Transactions.get_all_transactions()
        else
            Transactions.get_transactions_by_user_id(id)
        end
    end
end
    