defmodule FlightWeb.API.Invoices.CustomLineItemControllerTest do
  use FlightWeb.ConnCase

  alias Flight.Repo
  alias Flight.Billing.InvoiceCustomLineItem

  describe "POST /api/invoices/:school_id/custom_line_items" do
    test "unauthorized", %{conn: conn} do
      admin = admin_fixture()
      superadmin = superadmin_fixture(%{}, school_fixture())
      school_id = admin.school_id
      another_school_id = superadmin.school_id

      payload = %{
        custom_line_item: %{
          default_rate: 200,
          description: "Fuel Charge"
        }
      }

      conn =
        conn
        |> auth(admin)

      conn
      |> post("/api/invoices/#{school_id}/custom_line_items", payload)
      |> json_response(200)

      conn
      |> post("/api/invoices/#{another_school_id}/custom_line_items", payload)
      |> response(401)

      payload = %{
        custom_line_item: %{
          description: "Fuel Reimbursement",
          default_rate: 250
        }
      }

      conn =
        conn
        |> auth(superadmin)

      conn
      |> post("/api/invoices/#{school_id}/custom_line_items", payload)
      |> json_response(200)

      conn
      |> post("/api/invoices/#{another_school_id}/custom_line_items", payload)
      |> json_response(200)
    end

    test "create", %{conn: conn} do
      admin = admin_fixture()
      school_id = admin.school_id

      payload = %{
        custom_line_item: %{
          default_rate: 200,
          description: "Fuel Charge"
        }
      }

      conn =
        conn
        |> auth(admin)

      json =
        conn
        |> post("/api/invoices/#{school_id}/custom_line_items", payload)
        |> json_response(200)

      assert custom_line_item = Repo.get_by(InvoiceCustomLineItem, school_id: school_id)

      assert json == %{
               "id" => custom_line_item.id,
               "description" => "Fuel Charge",
               "default_rate" => 200,
               "school_id" => school_id
             }

      json =
        conn
        |> post("/api/invoices/#{school_id}/custom_line_items", payload)
        |> json_response(422)

      assert json == %{"errors" => %{"description" => ["has already been taken"]}}

      payload = %{
        custom_line_item: %{
          default_rate: 10_000_000,
          description: "Fuel Reimbursement"
        }
      }

      json =
        conn
        |> post("/api/invoices/#{school_id}/custom_line_items", payload)
        |> json_response(422)

      assert json == %{"errors" => %{"default_rate" => ["must be less than 10,000"]}}
    end
  end

  describe "PATCH /api/invoices/:school_id/custom_line_items/:id" do
    test "unauthorized", %{conn: conn} do
      admin = admin_fixture()
      superadmin = superadmin_fixture(%{}, school_fixture())
      school_id = admin.school_id
      another_school_id = superadmin.school_id

      custom_line_item =
        invoice_custom_line_item_fixture(%{
          description: "Fuel Charge",
          school_id: school_id
        })

      another_custom_line_item =
        invoice_custom_line_item_fixture(%{
          description: "Fuel Charge",
          school_id: another_school_id
        })

      id = custom_line_item.id
      another_id = another_custom_line_item.id

      payload = %{
        custom_line_item: %{
          default_rate: 200,
          description: "Fuel Reimbursement"
        }
      }

      conn =
        conn
        |> auth(admin)

      conn
      |> patch("/api/invoices/#{school_id}/custom_line_items/#{id}", payload)
      |> json_response(200)

      conn
      |> patch("/api/invoices/#{another_school_id}/custom_line_items/#{another_id}", payload)
      |> response(401)

      conn =
        conn
        |> auth(superadmin)

      conn
      |> patch("/api/invoices/#{school_id}/custom_line_items/#{id}", payload)
      |> json_response(200)
    end

    test "update", %{conn: conn} do
      admin = admin_fixture()
      school_id = admin.school_id

      custom_line_item =
        invoice_custom_line_item_fixture(%{
          description: "Test school",
          school_id: school_id
        })

      another_custom_line_item =
        invoice_custom_line_item_fixture(%{
          description: "Fuel Charge",
          school_id: school_id
        })

      payload = %{
        custom_line_item: %{
          default_rate: 200,
          description: "Fuel Reimbursement"
        }
      }

      conn =
        conn
        |> auth(admin)

      id = custom_line_item.id

      assert custom_line_item = Repo.get(InvoiceCustomLineItem, id)
      assert custom_line_item.default_rate == 100
      assert custom_line_item.description == "Test school"

      json =
        conn
        |> patch("/api/invoices/#{school_id}/custom_line_items/#{id}", payload)
        |> json_response(200)

      assert custom_line_item = Repo.get(InvoiceCustomLineItem, id)
      assert custom_line_item.default_rate == 200
      assert custom_line_item.description == "Fuel Reimbursement"

      assert json == %{
               "id" => custom_line_item.id,
               "description" => "Fuel Reimbursement",
               "default_rate" => 200,
               "school_id" => school_id
             }

      payload = %{
        custom_line_item: %{
          description: "Fuel Charge"
        }
      }

      json =
        conn
        |> patch("/api/invoices/#{school_id}/custom_line_items/#{id}", payload)
        |> json_response(422)

      assert json == %{"errors" => %{"default_rate" => ["can't be blank"]}}

      payload = %{
        custom_line_item: %{
          default_rate: 200,
          description: "Fuel Charge"
        }
      }

      assert custom_line_item = Repo.get(InvoiceCustomLineItem, another_custom_line_item.id)
      assert custom_line_item.description == "Fuel Charge"

      json =
        conn
        |> patch("/api/invoices/#{school_id}/custom_line_items/#{id}", payload)
        |> json_response(422)

      assert json == %{"errors" => %{"description" => ["has already been taken"]}}

      payload = %{
        custom_line_item: %{
          default_rate: 1_000_000
        }
      }

      json =
        conn
        |> patch("/api/invoices/#{school_id}/custom_line_items/#{id}", payload)
        |> json_response(422)

      assert json == %{
               "errors" => %{
                 "default_rate" => ["must be less than 10,000"],
                 "description" => ["can't be blank"]
               }
             }
    end
  end

  describe "DELETE /api/invoices/:school_id/custom_line_items/:id" do
    test "unauthorized", %{conn: conn} do
      admin = admin_fixture()
      superadmin = superadmin_fixture(%{}, school_fixture())
      school_id = admin.school_id
      another_school_id = superadmin.school_id
      custom_line_item = invoice_custom_line_item_fixture(%{school_id: school_id})
      another_custom_line_item = invoice_custom_line_item_fixture(%{school_id: another_school_id})

      conn =
        conn
        |> auth(admin)

      conn
      |> delete(
        "/api/invoices/#{another_school_id}/custom_line_items/#{another_custom_line_item.id}"
      )
      |> response(401)

      conn =
        conn
        |> auth(superadmin)

      conn
      |> delete("/api/invoices/#{school_id}/custom_line_items/#{custom_line_item.id}")
      |> response(204)
    end

    test "delete", %{conn: conn} do
      admin = admin_fixture()
      school_id = admin.school_id
      custom_line_item = invoice_custom_line_item_fixture(%{school_id: school_id})

      conn =
        conn
        |> auth(admin)

      conn
      |> delete("/api/invoices/#{school_id}/custom_line_items/#{custom_line_item.id}")
      |> response(204)
    end
  end
end
