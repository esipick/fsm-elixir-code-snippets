defmodule Flight.Curriculum.Course do
  use Ecto.Schema
  import Ecto.Changeset

  schema "courses" do
    field(:name, :string)
    field(:order, :integer, default: 0)
    has_many(:lessons, Flight.Curriculum.Lesson)
    has_many(:course_downloads, Flight.Curriculum.CourseDownload)

    timestamps()
  end

  @doc false
  def changeset(course, attrs) do
    course
    |> cast(attrs, [:name, :order])
    |> validate_required([:name, :order])
  end
end
