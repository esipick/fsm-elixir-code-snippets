defmodule FlightWeb.Admin.InvoicesController do
  use FlightWeb, :controller

  def new(conn, _) do
    props = %{
      sales_tax: conn.assigns.current_user.school.sales_tax || 0.25,
      action: "create"
    }

    render(conn, "new.html", props: props)
  end

  def edit(conn, _) do
    props = %{
      action: "edit"
    }

    render(conn, "edit.html", props: props)
  end
end
