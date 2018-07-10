defmodule FightWeb.API.CourseControllerTest do
  use FlightWeb.ConnCase
  import Flight.CurriculumFixtures

  describe "GET /api/courses" do
    test "renders courses", %{conn: conn} do
      course = course_fixture()
      course_download_fixture(%{}, course)
      lesson = lesson_fixture(%{}, course)
      lesson_category = lesson_category_fixture(%{}, lesson)
      objective_fixture(%{}, lesson_category)

      json =
        conn
        |> auth(student_fixture())
        |> get("/api/courses")
        |> json_response(200)

      courses =
        [course]
        |> Flight.Repo.preload([
          :course_downloads,
          lessons: [lesson_categories: [:objectives]]
        ])

      assert json == render_json(FlightWeb.API.CourseView, "index.json", courses: courses)
    end
  end
end
