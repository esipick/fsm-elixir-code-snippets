defmodule FsmWeb.GraphQL.Transactions.TransactionsResolvers do
    alias Fsm.Transactions
    require Logger

    def get_all_transactions(_parent, _args, _context) do
        Transactions.get_all_transactions()
    end
end
    