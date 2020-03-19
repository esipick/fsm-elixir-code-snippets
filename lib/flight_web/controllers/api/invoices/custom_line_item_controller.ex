defmodule FlightWeb.API.Invoices.CustomLineItemController do
  use FlightWeb, :controller

  alias FlightWeb.ViewHelpers
  alias Flight.Billing.InvoiceCustomLineItem

  plug(:authorize_admin)

  def create(conn, %{"custom_line_item" => data_params, "school_id" => school_id}) do
    case InvoiceCustomLineItem.create_custom_line_item(data_params, school_id) do
      {:ok, changeset} ->
        custom_line_item = %{
          default_rate: changeset.default_rate,
          description: changeset.description,
          id: changeset.id,
          school_id: changeset.school_id
        }

        conn
        |> put_status(200)
        |> json(custom_line_item)

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id, "school_id" => school_id}) do
    result = InvoiceCustomLineItem.delete_custom_line_item(id, school_id)

    case result do
      {:ok, _} ->
        conn
        |> resp(204, "")

      nil ->
        conn
        |> resp(404, "")
    end
  end

  def update(conn, %{"custom_line_item" => data_params, "id" => id, "school_id" => school_id}) do
    case InvoiceCustomLineItem.update_custom_line_item(data_params, id, school_id) do
      {:ok, changeset} ->
        custom_line_item = %{
          default_rate: changeset.default_rate,
          description: changeset.description,
          id: changeset.id,
          school_id: changeset.school_id
        }

        conn
        |> put_status(200)
        |> json(custom_line_item)

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> json(%{errors: ViewHelpers.translate_errors(changeset)})
    end
  end

  defp authorize_admin(%{params: %{"school_id" => school_id}} = conn, _) do
    conn
    |> halt_unless_user_can?([
      Flight.Auth.Permission.new(:invoice_custom_line_items, :modify, :all)
    ])
    |> halt_unless_right_school(String.to_integer(school_id))
  end

  defp halt_unless_right_school(%{assigns: %{current_user: user}} = conn, school_id) do
    cond do
      !Flight.Accounts.is_superadmin?(user) && user.school_id != school_id ->
        halt_unauthorized_response(conn)

      true ->
        conn
    end
  end
end
