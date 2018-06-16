defmodule Flight.Curriculum.ObjectiveScore do
  use Ecto.Schema
  import Ecto.Changeset

  schema "objective_scores" do
    field(:score, :integer)
    belongs_to(:user, Flight.Accounts.User)
    belongs_to(:objective, Flight.Curriculum.Objective)

    timestamps()
  end

  @doc false
  def changeset(objective_score, attrs) do
    objective_score
    |> cast(attrs, [:score, :user_id, :objective_id])
    |> validate_required([:score, :user_id, :objective_id])
    |> validate_inclusion(:score, 1..5)
  end
end
