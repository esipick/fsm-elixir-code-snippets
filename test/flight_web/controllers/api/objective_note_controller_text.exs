defmodule FlightWeb.API.ObjectiveNoteControllerTest do
  use FlightWeb.ConnCase

  import Flight.CurriculumFixtures

  alias FlightWeb.API.ObjectiveNoteView
  alias Flight.Curriculum.ObjectiveNote

  describe "GET /api/objective_notes" do
    test "renders objective notes for student", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()
      note = objective_note_fixture(%{note: "Heyo"}, student, objective)

      json =
        conn
        |> auth(student)
        |> get("/api/objective_notes?user_id=#{student.id}")
        |> json_response(200)

      assert List.first(json["data"])["note"] == "Heyo"

      assert json == render_json(ObjectiveNoteView, "index.json", objective_notes: [note])
    end

    test "renders for instructor", %{conn: conn} do
      student = student_fixture()

      conn
      |> auth(instructor_fixture())
      |> get("/api/objective_notes?user_id=#{student.id}")
      |> json_response(200)
    end

    test "401 if requested by another student", %{conn: conn} do
      student = student_fixture()
      other_student = student_fixture()

      conn
      |> auth(other_student)
      |> get("/api/objective_notes?user_id=#{student.id}")
      |> json_response(401)
    end
  end

  describe "POST /api/objective_notes" do
    test "creates new objective note if one doesn't exist", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()

      params = %{
        data: %{
          objective_id: objective.id,
          user_id: student.id,
          note: "Heyo bucko"
        }
      }

      json =
        conn
        |> auth(instructor_fixture())
        |> post("/api/objective_notes", params)
        |> json_response(200)

      assert note =
               Flight.Repo.get_by(
                 ObjectiveNote,
                 user_id: student.id,
                 objective_id: objective.id,
                 note: "Heyo bucko"
               )

      assert json == render_json(ObjectiveNoteView, "show.json", objective_note: note)
    end

    test "updates existing objective note if one does exist", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()
      note = objective_note_fixture(%{note: "Herro"}, student, objective)

      params = %{
        data: %{
          objective_id: objective.id,
          user_id: student.id,
          note: "Hi you"
        }
      }

      conn
      |> auth(instructor_fixture())
      |> post("/api/objective_notes", params)
      |> json_response(200)

      updated_note =
        Flight.Repo.get_by(
          ObjectiveNote,
          user_id: student.id,
          objective_id: objective.id,
          note: "Hi you"
        )

      assert updated_note.id == note.id
    end

    test "deletes existing note if the empty string is submitted", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()
      objective_note_fixture(%{note: "Herro"}, student, objective)

      params = %{
        data: %{
          objective_id: objective.id,
          user_id: student.id,
          note: ""
        }
      }

      conn
      |> auth(instructor_fixture())
      |> post("/api/objective_notes", params)
      |> json_response(200)

      refute Flight.Repo.get_by(
               ObjectiveNote,
               user_id: student.id,
               objective_id: objective.id
             )
    end

    test "students can't update their own objective notes", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()

      params = %{
        data: %{
          objective_id: objective.id,
          user_id: student.id,
          note: "Huh"
        }
      }

      conn
      |> auth(student)
      |> post("/api/objective_notes", params)
      |> json_response(401)

      refute Flight.Repo.get_by(
               ObjectiveNote,
               user_id: student.id,
               objective_id: objective.id,
               note: "Huh"
             )
    end
  end

  describe "DELETE /api/objective_notes" do
    test "deletes objective note", %{conn: conn} do
      note = objective_note_fixture()

      params = %{
        data: %{
          objective_id: note.objective.id,
          user_id: note.user.id
        }
      }

      conn
      |> auth(instructor_fixture())
      |> delete("/api/objective_notes", params)
      |> response(204)

      refute Flight.Repo.get(ObjectiveNote, note.id)
    end

    test "student can't delete notes", %{conn: conn} do
      note = objective_note_fixture()

      params = %{
        data: %{
          objective_id: note.objective.id,
          user_id: note.user.id
        }
      }

      conn
      |> auth(note.user)
      |> delete("/api/objective_notes", params)
      |> response(401)
    end
  end
end
