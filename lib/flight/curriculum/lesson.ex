defmodule Flight.Curriculum.Lesson do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lessons" do
    field(:name, :string)
    field(:order, :integer, default: 0)
    field(:syllabus_url, :string)
    field(:syllabus_version, :integer, default: 1)
    belongs_to(:course, Flight.Curriculum.Course)
    has_many(:lesson_categories, Flight.Curriculum.LessonCategory)

    timestamps()
  end

  @doc false
  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:name, :course_id, :order, :syllabus_url, :syllabus_version])
    |> validate_required([:name, :course_id, :order, :syllabus_version])
  end
end
