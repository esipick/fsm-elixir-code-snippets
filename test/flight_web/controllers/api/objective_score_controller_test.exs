defmodule FlightWeb.API.ObjectiveScoreControllerTest do
  use FlightWeb.ConnCase

  import Flight.CurriculumFixtures

  alias FlightWeb.API.ObjectiveScoreView
  alias Flight.Curriculum.ObjectiveScore

  describe "GET /api/objective_scores" do
    test "renders objective scores for student", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()
      score = objective_score_fixture(%{score: 3}, student, objective)

      json =
        conn
        |> auth(student)
        |> get("/api/objective_scores?user_id=#{student.id}")
        |> json_response(200)

      assert json == render_json(ObjectiveScoreView, "index.json", objective_scores: [score])
    end

    test "renders for instructor", %{conn: conn} do
      student = student_fixture()

      conn
      |> auth(instructor_fixture())
      |> get("/api/objective_scores?user_id=#{student.id}")
      |> json_response(200)
    end

    test "401 if requested by another student", %{conn: conn} do
      student = student_fixture()
      other_student = student_fixture()

      conn
      |> auth(other_student)
      |> get("/api/objective_scores?user_id=#{student.id}")
      |> json_response(401)
    end
  end

  describe "POST /api/objective_scores" do
    test "creates new objective score if one doesn't exist", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()

      params = %{
        data: %{
          objective_id: objective.id,
          user_id: student.id,
          score: 3
        }
      }

      json =
        conn
        |> auth(instructor_fixture())
        |> post("/api/objective_scores", params)
        |> json_response(200)

      assert score =
               Flight.Repo.get_by(
                 ObjectiveScore,
                 user_id: student.id,
                 objective_id: objective.id,
                 score: 3
               )

      assert json == render_json(ObjectiveScoreView, "show.json", objective_score: score)
    end

    test "updates existing objective score if one does exist", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()
      score = objective_score_fixture(%{score: 3}, student, objective)

      params = %{
        data: %{
          objective_id: objective.id,
          user_id: student.id,
          score: 2
        }
      }

      conn
      |> auth(instructor_fixture())
      |> post("/api/objective_scores", params)
      |> json_response(200)

      updated_score =
        Flight.Repo.get_by(
          ObjectiveScore,
          user_id: student.id,
          objective_id: objective.id,
          score: 2
        )

      assert updated_score.id == score.id
    end

    test "students can't update their own objective scores", %{conn: conn} do
      student = student_fixture()
      objective = objective_fixture()

      params = %{
        data: %{
          objective_id: objective.id,
          user_id: student.id,
          score: 3
        }
      }

      conn
      |> auth(student)
      |> post("/api/objective_scores", params)
      |> json_response(401)

      refute Flight.Repo.get_by(
               ObjectiveScore,
               user_id: student.id,
               objective_id: objective.id,
               score: 3
             )
    end
  end

  describe "DELETE /api/objective_scores" do
    test "deletes objective score", %{conn: conn} do
      score = objective_score_fixture()

      params = %{
        data: %{
          objective_id: score.objective.id,
          user_id: score.user.id
        }
      }

      conn
      |> auth(instructor_fixture())
      |> delete("/api/objective_scores", params)
      |> response(204)

      refute Flight.Repo.get(ObjectiveScore, score.id)
    end

    test "student can't delete scores", %{conn: conn} do
      score = objective_score_fixture()

      params = %{
        data: %{
          objective_id: score.objective.id,
          user_id: score.user.id
        }
      }

      conn
      |> auth(score.user)
      |> delete("/api/objective_scores", params)
      |> response(401)
    end
  end
end
