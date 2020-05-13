defmodule Mix.Tasks.FixTransactions do
  use Mix.Task

  import Ecto.Query
  alias Flight.{Billing, Repo}
  alias Billing.{CalculateInvoice, Invoice, Transaction}

  @shortdoc "Creates invoices for incompleted student transactions"
  def run(_) do
    [:postgrex, :ecto, :tzdata]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    IO.puts("Get transactions")

    transactions =
      Transaction
      |> where([a], a.state == "pending")
      |> Repo.all()
      |> Repo.preload([:line_items, :school, :user])

    for transaction <- transactions do
      IO.puts("Read transaction with id #{transaction.id}")

      case transaction.invoice_id do
        nil ->
          payer_name =
            case transaction.user do
              nil ->
                String.trim("#{transaction.first_name} #{transaction.last_name}")

              user ->
                "#{user.first_name} #{user.last_name}"
            end

          line_items =
            Enum.map(transaction.line_items, fn line_item ->
              amount = Map.get(line_item, :amount)

              type =
                case Map.get(line_item, :type) do
                  "custom" -> "other"
                  type -> type
                end

              description =
                case type do
                  "aircraft" -> "Flight Hours"
                  "instructor" -> "Instructor Hours"
                  _ -> Map.get(line_item, :description)
                end

              quantity = Map.get(line_item, :quantity, 1)
              rate = Map.get(line_item, :rate, amount)
              aircraft_id = Map.get(line_item, :aircraft_id)
              instructor_user_id = Map.get(line_item, :instructor_user_id)
              taxable = Map.get(line_item, :taxable, false) or type != "instructor"

              %{
                "aircraft_id" => aircraft_id,
                "amount" => amount,
                "description" => description,
                "instructor_user_id" => instructor_user_id,
                "quantity" => quantity,
                "rate" => rate,
                "taxable" => taxable,
                "type" => type
              }
            end)

          invoice_params = %{"line_items" => line_items}

          case CalculateInvoice.run(invoice_params, transaction.school) do
            {:ok, calculated_params} ->
              tax_rate = Map.get(calculated_params, "tax_rate")
              total = Map.get(calculated_params, "total")
              total_amount_due = Map.get(calculated_params, "total_amount_due")
              total_tax = Map.get(calculated_params, "total_tax")

              attrs = %{
                created_at: transaction.inserted_at,
                date: transaction.updated_at,
                line_items: line_items,
                payer_name: payer_name,
                payment_option: "balance",
                school_id: transaction.school.id,
                tax_rate: tax_rate,
                total: total,
                total_amount_due: total_amount_due,
                total_tax: total_tax,
                updated_at: transaction.updated_at,
                user_id: transaction.user_id
              }

              IO.puts("Create invoice for transaction with id #{transaction.id}")

              case Invoice.create(attrs) do
                {:ok, invoice} ->
                  IO.puts("Invoice with id #{invoice.id} created")

                  transaction
                  |> Transaction.changeset(%{state: "canceled"})
                  |> Repo.update()

                  IO.puts("Transaction with id #{transaction.id} is canceled")

                {:error, changeset} ->
                  IO.inspect(changeset)
              end
          end

        _ ->
          IO.inspect("invoice exists for transaction with id #{transaction.id}")
      end
    end
  end
end
