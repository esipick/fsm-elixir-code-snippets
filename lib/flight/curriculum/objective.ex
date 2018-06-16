defmodule Flight.Curriculum.Objective do
  use Ecto.Schema
  import Ecto.Changeset

  schema "objectives" do
    field(:name, :string)
    belongs_to(:lesson_category, Flight.Curriculum.LessonCategory)

    timestamps()
  end

  @doc false
  def changeset(objective, attrs) do
    objective
    |> cast(attrs, [:name, :lesson_category_id])
    |> validate_required([:name])
  end
end
