defmodule Flight.Scheduling do
  alias Flight.Scheduling.{Aircraft}
  alias Flight.Repo

  def create_aircraft(attrs) do
    %Aircraft{}
    |> Aircraft.changeset(attrs)
    |> Repo.insert()
  end

  def visible_aircrafts() do
    Repo.all(Aircraft)
  end

  def get_aircraft(id), do: Repo.get(Aircraft, id)

  def update_aircraft(aircraft, attrs) do
    aircraft
    |> Aircraft.changeset(attrs)
    |> Repo.update()
  end
end
