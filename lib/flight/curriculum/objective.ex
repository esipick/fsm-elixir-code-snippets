defmodule Flight.Curriculum.Objective do
  use Ecto.Schema
  import Ecto.Changeset

  schema "objectives" do
    field(:name, :string)
    field(:order, :integer, default: 0)
    belongs_to(:lesson_category, Flight.Curriculum.LessonCategory)

    timestamps()
  end

  @doc false
  def changeset(objective, attrs) do
    objective
    |> cast(attrs, [:name, :lesson_category_id, :order])
    |> validate_required([:name, :order])
  end
end
