defmodule FlightWeb.API.ObjectiveNoteView do
  use FlightWeb, :view

  def render("index.json", %{objective_notes: notes}) do
    %{
      data: render_many(notes, __MODULE__, "objective_note.json", as: :objective_note)
    }
  end

  def render("objective_note.json", %{objective_note: note}) do
    %{
      id: note.id,
      user_id: note.user_id,
      objective_id: note.objective_id,
      note: note.note
    }
  end

  def render("show.json", %{objective_note: note}) do
    %{
      data: render("objective_note.json", objective_note: note)
    }
  end
end
