defmodule Flight.Curriculum do
  alias Flight.Repo

  alias Flight.Curriculum.{
    Course,
    CourseDownload,
    Lesson,
    LessonCategory,
    Objective,
    ObjectiveScore,
    ObjectiveNote
  }

  require Ecto.Query
  import Ecto.Query, warn: false

  def get_courses() do
    course_query = from(t in Course, order_by: t.order)
    course_download_query = from(t in CourseDownload, order_by: t.order)
    lesson_query = from(t in Lesson, order_by: t.order)
    lesson_category_query = from(t in LessonCategory, order_by: t.order)
    objective_query = from(t in Objective, order_by: t.order)

    Repo.all(course_query)
    |> Flight.Repo.preload([
      [course_downloads: course_download_query],
      lessons: lesson_query,
      lessons: [
        lesson_categories: lesson_category_query,
        lesson_categories: [objectives: objective_query]
      ]
    ])
  end

  def get_objective_scores(user_id) do
    from(s in ObjectiveScore, where: s.user_id == ^user_id)
    |> Repo.all()
  end

  def get_objective_score(user_id, objective_id),
    do: Repo.get_by(ObjectiveScore, user_id: user_id, objective_id: objective_id)

  def delete_objective_score(score), do: Repo.delete!(score)

  def set_objective_score(data) do
    score =
      Repo.get_by(ObjectiveScore, user_id: data["user_id"], objective_id: data["objective_id"]) ||
        %ObjectiveScore{}

    score
    |> ObjectiveScore.changeset(data)
    |> Repo.insert_or_update()
  end

  def get_objective_notes(user_id) do
    from(s in ObjectiveNote, where: s.user_id == ^user_id)
    |> Repo.all()
  end

  def get_objective_note(user_id, objective_id),
    do: Repo.get_by(ObjectiveNote, user_id: user_id, objective_id: objective_id)

  def delete_objective_note(note), do: Repo.delete!(note)

  def set_objective_note(data) do
    note =
      Repo.get_by(ObjectiveNote, user_id: data["user_id"], objective_id: data["objective_id"]) ||
        %ObjectiveNote{}

    if data["note"] |> String.trim() |> String.length() == 0 do
      Repo.delete(note)
    else
      note
      |> ObjectiveNote.changeset(data)
      |> Repo.insert_or_update()
    end
  end
end
