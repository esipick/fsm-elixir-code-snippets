defmodule FsmWeb.GraphQL.Billing.InvoicesResolvers do

  alias Fsm.Billing.Invoices
  alias FsmWeb.GraphQL.Log

  def list_custom_line_items(parent, args, %{context: %{current_user: %{school_id: _school_id}}}=context) do
    users = Invoices.list_custom_line_items(context)

    resp = {:ok, users}
    Log.response(resp, __ENV__.function, :info)
  end
end
  