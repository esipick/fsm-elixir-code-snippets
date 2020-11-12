defmodule Fsm.Transactions do
    import Ecto.Query, warn: false
  
    alias Flight.Repo
    alias Fsm.Transactions.TransactionsQueries
    require Logger
  
    def get_transactions(user_id, page, per_page, sort_field, sort_order, filter, context) do
        TransactionsQueries.list_bills_query(user_id, page, per_page, sort_field, sort_order, filter, context)
        |> Repo.all
        |> case do
            nil ->
                {:ok, nil}
            data ->
                data = Enum.map(data, fn i -> 
                    transactions = Map.get(i, :transactions)
                    |> Enum.map(fn transaction ->  %{
                        id: Map.get(transaction, "id"),
                        total: Map.get(transaction, "total"), 
                        paid_by_balance: Map.get(transaction, "paid_by_balance"), 
                        paid_by_charge: Map.get(transaction, "paid_by_charge"), 
                        stripe_charge_id: Map.get(transaction, "stripe_charge_id"), 
                        state: Map.get(transaction, "state"), 
                        creator_user_id: Map.get(transaction, "creator_user_id"),
                        completed_at: Map.get(transaction, "completed_at"), 
                        type: Map.get(transaction, "type"), 
                        first_name: Map.get(transaction, "first_name"), 
                        last_name: Map.get(transaction, "last_name"), 
                        email: Map.get(transaction, "email"), 
                        paid_by_cash: Map.get(transaction, "paid_by_cash"), 
                        paid_by_check: Map.get(transaction, "paid_by_check"), 
                        paid_by_venmo: Map.get(transaction, "paid_by_venmo"), 
                        payment_option: Map.get(transaction, "payment_option")} 
                    end)

                    %{
                        id: i.id,
                        date: i.date,
                        total: i.total,
                        tax_rate: i.tax_rate,
                        total_tax: i.total_tax,
                        total_amount_due: i.total_amount_due,
                        status: i.status,
                        payment_option: i.payment_option,
                        payer_name: payer_name(i),
                        demo: i.demo,
                        archived: i.archived,
                        is_visible: i.is_visible,
                        archived_at: i.archived_at,
                        appointment_updated_at: i.appointment_updated_at,
                        appointment_id: i.appointment_id,
                        # aircraft_info: i.aircraft_info,
                        session_id: i.session_id,
                        transactions: transactions
                        }
                    end)
                {:ok, data}
        end
    end  

    defp payer_name(invoice) do
        user = Map.get(invoice, :user)
        Map.get(invoice, :payer_name)  
        |> payer_name(user) 
    end

    defp payer_name(payer_name, user) when payer_name == nil do
        user_first_name = Map.get(user, :first_name)
        user_last_name = Map.get(user, :last_name)
        user_first_name<>" "<>user_last_name
    end

    defp payer_name(payer_name, _user) when payer_name != nil do
        payer_name
    end
  end
  