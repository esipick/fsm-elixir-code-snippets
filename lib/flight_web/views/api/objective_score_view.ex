defmodule FlightWeb.API.ObjectiveScoreView do
  use FlightWeb, :view

  def render("index.json", %{objective_scores: scores}) do
    %{
      data: render_many(scores, __MODULE__, "objective_score.json", as: :objective_score)
    }
  end

  def render("objective_score.json", %{objective_score: score}) do
    %{
      id: score.id,
      user_id: score.user_id,
      objective_id: score.objective_id,
      score: score.score
    }
  end

  def render("show.json", %{objective_score: score}) do
    %{
      data: render("objective_score.json", objective_score: score)
    }
  end
end
