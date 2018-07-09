defmodule FlightWeb.API.TransactionView do
  use FlightWeb, :view

  def render("preview.json", %{
        transaction: transaction,
        instructor_line_item: instructor_line_item,
        aircraft_line_item: aircraft_line_item
      }) do
    %{
      data: %{
        total: transaction.total,
        line_items:
          [
            Optional.map(instructor_line_item, fn item ->
              %{
                label: "Instructor",
                amount: item.amount
              }
            end),
            Optional.map(aircraft_line_item, fn item ->
              %{
                label: "Aircraft",
                amount: item.amount
              }
            end)
          ]
          |> Enum.filter(& &1)
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
      user: render(FlightWeb.API.UserView, "skinny_user.json", user: transaction.user),
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
  end

  def render("line_item.json", %{line_item: line_item}) do
    %{
      amount: line_item.amount,
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
