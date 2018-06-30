defmodule Flight.CurriculumFixtures do
  alias Flight.Curriculum.{
    Course,
    Lesson,
    CourseDownload,
    LessonCategory,
    Objective,
    ObjectiveScore,
    ObjectiveNote,
    Syllabus
  }

  alias Flight.Repo

  import Flight.AccountsFixtures

  def course_fixture(attrs \\ %{}) do
    %Course{
      name: "Some course"
    }
    |> Course.changeset(attrs)
    |> Repo.insert!()
  end

  def course_download_fixture(attrs \\ %{}, course \\ course_fixture()) do
    course_download =
      %CourseDownload{
        name: "Some course download",
        url: "https://google.com",
        course_id: course.id
      }
      |> CourseDownload.changeset(attrs)
      |> Repo.insert!()

    %{course_download | course: course}
  end

  def lesson_fixture(attrs \\ %{}, course \\ course_fixture()) do
    lesson =
      %Lesson{
        name: "Some category",
        course_id: course.id
      }
      |> Lesson.changeset(attrs)
      |> Repo.insert!()

    %{lesson | course: course}
  end

  def lesson_category_fixture(attrs \\ %{}, lesson \\ lesson_fixture()) do
    lesson_category =
      %LessonCategory{
        name: "Some category",
        lesson_id: lesson.id
      }
      |> LessonCategory.changeset(attrs)
      |> Repo.insert!()

    %{lesson_category | lesson: lesson}
  end

  def objective_fixture(attrs \\ %{}, lesson_category \\ lesson_category_fixture()) do
    objective =
      %Objective{
        name: "Some objective",
        lesson_category_id: lesson_category.id
      }
      |> Objective.changeset(attrs)
      |> Repo.insert!()

    %{objective | lesson_category: lesson_category}
  end

  def objective_score_fixture(
        attrs \\ %{},
        user \\ user_fixture(),
        objective \\ objective_fixture()
      ) do
    score =
      %ObjectiveScore{
        user_id: user.id,
        objective_id: objective.id,
        score: 3
      }
      |> ObjectiveScore.changeset(attrs)
      |> Repo.insert!()

    %{score | user: user, objective: objective}
  end

  def objective_note_fixture(
        attrs \\ %{},
        user \\ user_fixture(),
        objective \\ objective_fixture()
      ) do
    note =
      %ObjectiveNote{
        user_id: user.id,
        objective_id: objective.id,
        note: "Hello you"
      }
      |> ObjectiveNote.changeset(attrs)
      |> Repo.insert!()

    %{note | user: user, objective: objective}
  end

  def syllabus_fixture(attrs \\ %{}, lesson \\ lesson_fixture()) do
    syllabus =
      %Syllabus{
        lesson_id: lesson.id
      }
      |> Syllabus.changeset(attrs)
      |> Repo.insert!()

    %{syllabus | lesson: lesson}
  end
end
