defmodule Flight.Curriculum.Syllabus do
  use Ecto.Schema
  import Ecto.Changeset

  schema "syllabuses" do
    belongs_to(:lesson, Flight.Curriculum.Lesson)

    timestamps()
  end

  @doc false
  def changeset(syllabus, attrs) do
    syllabus
    |> cast(attrs, [:lesson_id])
    |> validate_required([:lesson_id])
  end
end
