defmodule Flight.Curriculum.CourseDownload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "course_downloads" do
    field(:name, :string)
    field(:url, :string)
    field(:version, :integer, default: 1)
    belongs_to(:course, Flight.Curriculum.Course)

    timestamps()
  end

  @doc false
  def changeset(course_download, attrs) do
    course_download
    |> cast(attrs, [:name, :course_id])
    |> validate_required([:name, :course_id])
  end
end
