defmodule Flight.Aircrafts do
    alias Flight.Aircraft.Queries
    alias Flight.Scheduling.Aircraft
    alias Flight.Repo

    def get_aircraft(nil, _school_id), do: {:error, "Invalid Id"}
    def get_aircraft(id, school_id) do
        Repo.get_by(Aircraft, id: id, school_id: school_id)
        |> case do
            nil -> {:error, "Aircraft with id: #{id} not found."}
            aircraft -> 
                {:ok, Repo.preload(aircraft, [:maintenance])}
        end
    end
end