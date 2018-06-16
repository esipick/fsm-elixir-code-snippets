defmodule Flight.Curriculum.Lesson do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lessons" do
    field(:name, :string)
    belongs_to(:course, Flight.Curriculum.Course)
    has_one(:syllabus, Flight.Curriculum.Syllabus)
    has_many(:lesson_categories, Flight.Curriculum.LessonCategory)

    timestamps()
  end

  @doc false
  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:name, :course_id])
    |> validate_required([:name, :course_id])
  end
end
