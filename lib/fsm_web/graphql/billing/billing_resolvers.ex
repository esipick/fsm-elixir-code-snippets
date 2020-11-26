defmodule FsmWeb.GraphQL.Billing.BillingResolvers do
  alias Fsm.Billing
  require Logger

  def get_all_transactions(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)
    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}

    if "admin" in roles or "dispatcher" in roles do
      Billing.get_transactions(nil, page, per_page, sort_field, sort_order, filter, context)
    else
      Billing.get_transactions(id, page, per_page, sort_field, sort_order, filter, context)
    end
  end

  def add_funds(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
    amount = Map.get(args, :amount)
    description = Map.get(args, :description)
    requested_user_id = Map.get(args, :user_id)

    Billing.add_funds(%{user_id: id}, %{
      amount: amount,
      description: description,
      user_id: requested_user_id
    })
  end

  def fetch_card(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
    user_id = Map.get(args, :user_id)
    Billing.fetch_card(user_id)
  end

  def add_credit_card(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
    stripe_token = Map.get(args, :stripe_token)
    user_id = Map.get(args, :user_id)
    Billing.add_credit_card(stripe_token, user_id)
  end

  def create_invoice(
        parent,
        args,
        %{context: %{current_user: %{school_id: school_id, roles: roles, id: id}}} = context
      ) do
        invoice = Map.get(args, :invoice)
        pay_off = Map.get(args, :pay_off)
        Billing.create_invoice(invoice, pay_off, school_id, id)
  end
end
