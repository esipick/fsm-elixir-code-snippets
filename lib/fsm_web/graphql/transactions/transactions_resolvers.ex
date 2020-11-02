defmodule FsmWeb.GraphQL.Transactions.TransactionsResolvers do
    alias Fsm.Transactions
    require Logger

    def get_all_transactions(parent, args, %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}}=context) do 
        page = Map.get(args, :page)
        per_page = Map.get(args, :per_page)
        sort_field = Map.get(args, :sort_field) || :inserted_at
        sort_order = Map.get(args, :sort_order) || :desc
        filter = Map.get(args, :filter) || %{}
        if "admin" in roles or "dispatcher" in roles do
            Transactions.get_transactions(nil, page, per_page, sort_field, sort_order, filter, context)

        else
            Transactions.get_transactions(id, page, per_page, sort_field, sort_order, filter, context)
        end
    end
end
    