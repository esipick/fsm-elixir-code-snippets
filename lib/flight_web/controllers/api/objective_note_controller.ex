defmodule FlightWeb.API.ObjectiveNoteController do
  use FlightWeb, :controller

  alias Flight.Curriculum

  alias Flight.Auth.Permission

  plug(:get_objective_notes when action in [:index])
  plug(:authorize_view when action in [:index])
  plug(:authorize_modify when action in [:create, :delete])

  def index(conn, %{"user_id" => _}) do
    render(conn, "index.json", objective_notes: conn.assigns.objective_notes)
  end

  def create(conn, %{"data" => data}) do
    with {:ok, note} <- Curriculum.set_objective_note(data) do
      render(conn, "show.json", objective_note: note)
    end
  end

  def delete(conn, %{"data" => %{"user_id" => user_id, "objective_id" => objective_id}}) do
    note = Curriculum.get_objective_note(user_id, objective_id)

    if note do
      Curriculum.delete_objective_note(note)
      resp(conn, 204, "")
    else
      resp(conn, 404, "")
    end
  end

  def get_objective_notes(conn, _) do
    assign(conn, :objective_notes, Curriculum.get_objective_notes(conn.params["user_id"]))
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
