defmodule FlightWeb.API.ObjectiveScoreController do
  use FlightWeb, :controller

  alias Flight.Curriculum

  alias Flight.Auth.Permission

  plug(:get_objective_scores when action in [:index])
  plug(:authorize_view when action in [:index])
  plug(:authorize_modify when action in [:create, :delete])

  def index(conn, %{"user_id" => _}) do
    render(conn, "index.json", objective_scores: conn.assigns.objective_scores)
  end

  def create(conn, %{"data" => data}) do
    with {:ok, score} <- Curriculum.set_objective_score(data) do
      render(conn, "show.json", objective_score: score)
    end
  end

  def delete(conn, %{"data" => %{"user_id" => user_id, "objective_id" => objective_id}}) do
    score = Curriculum.get_objective_score(user_id, objective_id)

    if score do
      Curriculum.delete_objective_score(score)
      resp(conn, 204, "")
    else
      resp(conn, 404, "")
    end
  end

  def get_objective_scores(conn, _) do
    assign(conn, :objective_scores, Curriculum.get_objective_scores(conn.params["user_id"]))
  end

  def authorize_view(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:objective_score, :view, :all),
      Permission.new(:objective_score, :view, {:personal, conn.params["user_id"]})
    ])
  end

  def authorize_modify(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:objective_score, :modify, :all)
    ])
  end
end
