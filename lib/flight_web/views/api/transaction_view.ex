defmodule FlightWeb.API.TransactionView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers, only: [label_for_line_item: 1]
  import Pipe

  def render("preview.json", %{transaction: transaction, line_items: line_items}) do
    %{
      data: %{
        total: transaction.total,
        line_items:
          Enum.map(line_items, fn item ->
            %{
              label: label_for_line_item(item),
              description: item.description,
              amount: item.amount
            }
          end)
      }
    }
  end

  def render("show.json", %{transaction: transaction}) do
    %{
      data: render("transaction.json", transaction: transaction)
    }
  end

  def render("index.json", %{transactions: transactions}) do
    %{
      data:
        render_many(
          transactions,
          FlightWeb.API.TransactionView,
          "transaction.json",
          as: :transaction
        )
    }
  end

  def render("transaction.json", %{transaction: transaction}) do
    %{
      id: transaction.id,
      inserted_at: transaction.inserted_at,
      completed_at: transaction.completed_at,
      total: transaction.total,
      type: transaction.type,
      creator_user:
        render(FlightWeb.API.UserView, "skinny_user.json", user: transaction.creator_user),
      state: transaction.state,
      paid_by_charge: transaction.paid_by_charge,
      paid_by_balance: transaction.paid_by_balance,
      line_items:
        render_many(
          transaction.line_items,
          FlightWeb.API.TransactionView,
          "line_item.json",
          as: :line_item
        )
    }
    |> pass_unless(transaction.user, fn map ->
      Map.merge(map, %{
        user: render(FlightWeb.API.UserView, "skinny_user.json", user: transaction.user)
      })
    end)
  end

  def render("line_item.json", %{line_item: line_item}) do
    %{
      amount: line_item.amount,
      label: label_for_line_item(line_item),
      description: line_item.description,
      aircraft_id: line_item.aircraft_id,
      instructor_user_id: line_item.instructor_user_id
    }
  end

  def render("preferred_payment_method.json", %{method: method}) do
    %{
      data: %{
        method: method
      }
    }
  end

  def preload(transaction) do
    Flight.Repo.preload(transaction, [:line_items, :user, :creator_user])
  end
end
