defmodule Flight.Curriculum.ObjectiveNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "objective_notes" do
    field(:note, :string)
    belongs_to(:user, Flight.Accounts.User)
    belongs_to(:objective, Flight.Curriculum.Objective)

    timestamps()
  end

  @doc false
  def changeset(objective_note, attrs) do
    objective_note
    |> cast(attrs, [:note, :user_id, :objective_id])
    |> validate_required([:note, :user_id, :objective_id])
  end
end
