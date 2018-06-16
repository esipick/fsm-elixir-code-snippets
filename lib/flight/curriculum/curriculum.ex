defmodule Flight.Curriculum do
  alias Flight.Repo
  alias Flight.Curriculum.{Course, ObjectiveScore}

  import Ecto.Changeset
  import Ecto.Query, warn: false

  def get_courses(), do: Repo.all(Course)

  def get_objective_scores(user_id) do
    from(s in ObjectiveScore, where: s.user_id == ^user_id)
    |> Repo.all()
  end

  def get_objective_score(user_id, objective_id),
    do: Repo.get_by(ObjectiveScore, user_id: user_id, objective_id: objective_id)

  def delete_objective_score(score), do: Repo.delete!(score)

  def set_objective_score(data) do
    score =
      Repo.get_by(ObjectiveScore, user_id: data["user_id"], objective_id: data["objective_id"]) ||
        %ObjectiveScore{}

    score
    |> ObjectiveScore.changeset(data)
    |> Repo.insert_or_update()
  end
end
