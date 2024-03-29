defmodule Flight.Curriculum.LessonCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lesson_categories" do
    field(:name, :string)
    field(:order, :integer, default: 0)
    belongs_to(:lesson, Flight.Curriculum.Lesson)
    has_many(:objectives, Flight.Curriculum.Objective)

    timestamps()
  end

  @doc false
  def changeset(lesson_category, attrs) do
    lesson_category
    |> cast(attrs, [:name, :lesson_id, :order])
    |> validate_required([:name, :lesson_id, :order])
  end
end
