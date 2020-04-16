defmodule FlightWeb.API.DocumentControllerTest do
  use FlightWeb.ConnCase

  alias Flight.{Accounts, Accounts.Document, Repo}
  alias FlightWeb.API.DocumentView

  describe "GET /api/users/:user_id/documents" do
    test "dispatcher, instructor, renter, student not authorized to GET student documents", %{
      conn: conn
    } do
      for slug <- Accounts.roles_visible_to("dispatcher") do
        school = school_fixture()
        student_id = student_fixture(%{}, school).id
        user = user_fixture(%{}, school) |> assign_role(Atom.to_string(slug))

        conn
        |> auth(user)
        |> get("/api/users/#{student_id}/documents")
        |> response(401)
      end
    end

    test "return documents", %{conn: conn} do
      student = student_fixture()
      student_id = student.id

      Document.create_document(%{"file" => upload_fixture(), "user_id" => student_id})

      json =
        conn
        |> auth(student)
        |> get("/api/users/#{student_id}/documents")
        |> json_response(200)

      page = Document.documents_by_page(student_id, %{page_size: 10}, "")

      assert json ==
               render_json(DocumentView, "index.json",
                 page: page,
                 timezone: student.school.timezone
               )
    end

    test "return documents with pagination", %{conn: conn} do
      student = student_fixture()
      student_id = student.id

      for i <- 0..11, i > 0 do
        Document.create_document(%{"file" => upload_fixture(), "user_id" => student_id})
      end

      json =
        conn
        |> auth(student)
        |> get("/api/users/#{student_id}/documents?page=2")
        |> json_response(200)

      page = Document.documents_by_page(student_id, %{page: 2, page_size: 10}, "")

      assert json ==
               render_json(DocumentView, "index.json",
                 page: page,
                 timezone: student.school.timezone
               )
    end

    test "return documents for search terms", %{conn: conn} do
      student = student_fixture()
      student_id = student.id
      timezone = student.school.timezone

      Document.create_document(%{"file" => upload_fixture(), "user_id" => student_id})

      json =
        conn
        |> auth(student)
        |> get("/api/users/#{student_id}/documents?search=margot")
        |> json_response(200)

      page = Document.documents_by_page(student_id, %{page_size: 10}, "")

      assert json ==
               render_json(DocumentView, "index.json",
                 page: page,
                 timezone: timezone
               )

      json =
        conn
        |> auth(student)
        |> get("/api/users/#{student_id}/documents?search=abc")
        |> json_response(200)

      page = Document.documents_by_page(student_id, %{page_size: 10}, "")

      refute json ==
               render_json(DocumentView, "index.json",
                 page: page,
                 timezone: timezone
               )
    end
  end

  describe "POST /api/users/:user_id/documents" do
    test "dispatcher, instructor, renter, student not authorized to POST with student id", %{
      conn: conn
    } do
      for slug <- Accounts.roles_visible_to("dispatcher") do
        school = school_fixture()
        student_id = student_fixture(%{}, school).id
        user = user_fixture(%{}, school) |> assign_role(Atom.to_string(slug))

        payload = %{"document" => %{"file" => upload_fixture()}}

        conn
        |> auth(user)
        |> post("/api/users/#{student_id}/documents", payload)
        |> response(401)
      end
    end

    test "returns document", %{conn: conn} do
      school = school_fixture()
      student_id = student_fixture(%{}, school).id

      payload = %{"document" => %{"file" => upload_fixture()}}

      json =
        conn
        |> auth(admin_fixture(%{}, school))
        |> post("/api/users/#{student_id}/documents", payload)
        |> json_response(200)

      document = Repo.get_by(Document, user_id: student_id)

      assert json ==
               render_json(DocumentView, "show.json",
                 document: document,
                 timezone: school.timezone
               )
    end

    test "can't create a document with invalid file size", %{conn: conn} do
      school = school_fixture()
      student_id = student_fixture(%{}, school).id
      payload = %{"document" => %{"file" => upload_fixture()}}
      Application.put_env(:flight, :file_size, 1000)

      json =
        conn
        |> auth(admin_fixture(%{}, school))
        |> post("/api/users/#{student_id}/documents", payload)
        |> json_response(422)

      Application.delete_env(:flight, :file_size)
      assert json == %{"errors" => %{"file" => ["size should not exceed 1000B"]}}
    end

    test "can't create a document with invalid file type", %{conn: conn} do
      school = school_fixture()
      student_id = student_fixture(%{}, school).id
      payload = %{"document" => %{"file" => upload_fixture("assets/static/js/schedule.min.js")}}

      json =
        conn
        |> auth(admin_fixture(%{}, school))
        |> post("/api/users/#{student_id}/documents", payload)
        |> json_response(422)

      assert json == %{"errors" => %{"file" => ["Should be \".jpg .pdf .png\" type."]}}
    end

    test "can't create a document with same file name", %{conn: conn} do
      school = school_fixture()
      student_id = student_fixture(%{}, school).id
      payload = %{"document" => %{"file" => upload_fixture()}}
      payload_same = %{"document" => %{"file" => upload_fixture()}}

      json =
        conn
        |> auth(admin_fixture(%{}, school))
        |> post("/api/users/#{student_id}/documents", payload)
        |> json_response(200)

      json =
        conn
        |> auth(admin_fixture(%{}, school))
        |> post("/api/users/#{student_id}/documents", payload_same)
        |> json_response(422)

      assert json == %{"errors" => %{"file" => ["Already uploaded file with this name"]}}
    end

    test "superadmin can upload documents to students from any school", %{conn: conn} do
      student = student_fixture()
      student_id = student.id

      payload = %{"document" => %{"file" => upload_fixture()}}

      json =
        conn
        |> auth(superadmin_fixture())
        |> post("/api/users/#{student_id}/documents", payload)
        |> json_response(200)

      document = Repo.get_by(Document, user_id: student_id)

      assert json ==
               render_json(DocumentView, "show.json",
                 document: document,
                 timezone: student.school.timezone
               )
    end

    test "student not authorized to upload documents", %{conn: conn} do
      student = student_fixture()
      payload = %{"document" => %{"file" => upload_fixture()}}

      conn
      |> auth(student)
      |> post("/api/users/#{student.id}/documents", payload)
      |> response(401)
    end

    test "instructor not authorized to upload documents", %{conn: conn} do
      instructor = instructor_fixture()
      payload = %{"document" => %{"file" => upload_fixture()}}

      conn
      |> auth(instructor)
      |> post("/api/users/#{instructor.id}/documents", payload)
      |> response(401)
    end

    test "dispatcher not authorized to upload documents", %{conn: conn} do
      dispatcher = dispatcher_fixture()
      payload = %{"document" => %{"file" => upload_fixture()}}

      conn
      |> auth(dispatcher)
      |> post("/api/users/#{dispatcher.id}/documents", payload)
      |> response(401)
    end
  end

  describe "DELETE /api/users/:user_id/documents/:id" do
    test "dispatcher, instructor, renter, student not authorized to POST with student id", %{
      conn: conn
    } do
      for slug <- Accounts.roles_visible_to("dispatcher") do
        school = school_fixture()
        student_id = student_fixture(%{}, school).id
        user = user_fixture(%{}, school) |> assign_role(Atom.to_string(slug))

        {:ok, %{document_with_file: document}} =
          Document.create_document(%{"file" => upload_fixture(), "user_id" => student_id})

        conn
        |> auth(user)
        |> delete("/api/users/#{student_id}/documents/#{document.id}")
        |> response(401)
      end
    end

    test "deletes document", %{conn: conn} do
      school = school_fixture()
      student_id = student_fixture(%{}, school).id

      {:ok, %{document_with_file: document}} =
        Document.create_document(%{"file" => upload_fixture(), "user_id" => student_id})

      conn
      |> auth(admin_fixture(%{}, school))
      |> delete("/api/users/#{student_id}/documents/#{document.id}")
      |> response(204)

      refute Repo.get_by(Document, user_id: student_id)
    end

    test "superadmin can delete documents to students from any school", %{conn: conn} do
      student_id = student_fixture().id

      {:ok, %{document_with_file: document}} =
        Document.create_document(%{"file" => upload_fixture(), "user_id" => student_id})

      conn
      |> auth(superadmin_fixture())
      |> delete("/api/users/#{student_id}/documents/#{document.id}")
      |> response(204)

      refute Repo.get_by(Document, user_id: student_id)
    end

    test "student not authorized to delete documents", %{conn: conn} do
      student = student_fixture()
      student_id = student.id

      {:ok, %{document_with_file: document}} =
        Document.create_document(%{"file" => upload_fixture(), "user_id" => student_id})

      conn
      |> auth(student)
      |> delete("/api/users/#{student_id}/documents/#{document.id}")
      |> response(401)

      assert Repo.get_by(Document, user_id: student_id)
    end

    test "instructor not authorized to delete documents", %{conn: conn} do
      instructor = instructor_fixture()
      instructor_id = instructor.id

      {:ok, %{document_with_file: document}} =
        Document.create_document(%{"file" => upload_fixture(), "user_id" => instructor_id})

      conn
      |> auth(instructor)
      |> delete("/api/users/#{instructor_id}/documents/#{document.id}")
      |> response(401)

      assert Repo.get_by(Document, user_id: instructor_id)
    end

    test "dispatcher not authorized to delete documents", %{conn: conn} do
      dispatcher = dispatcher_fixture()
      dispatcher_id = dispatcher.id

      {:ok, %{document_with_file: document}} =
        Document.create_document(%{"file" => upload_fixture(), "user_id" => dispatcher_id})

      conn
      |> auth(dispatcher)
      |> delete("/api/users/#{dispatcher_id}/documents/#{document.id}")
      |> response(401)

      assert Repo.get_by(Document, user_id: dispatcher_id)
    end
  end
end
