defmodule Flight.DataCaseHelpers do
  def refresh(ecto_struct) do
    Flight.Repo.get(ecto_struct.__struct__, ecto_struct.id)
  end
end
