defmodule Fsm.School do

  alias Fsm.School.SchoolQueries
  alias Fsm.Schema.School

  alias Flight.Repo

  def get_school(school_id) do
    Repo.get(School, school_id)
    |> case do
      nil ->
        {:error, :data_not_found}
      school ->
        {:ok, school}
      end
  end
end
