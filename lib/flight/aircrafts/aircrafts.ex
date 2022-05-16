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

    def airworthiness(aircraft) do
        now = Timex.today()
        registration_cert_status =
            case aircraft.registration_certificate_expires_at do
                nil ->
                    "No registration certificate."

                _ ->
                    case Date.compare(now, aircraft.registration_certificate_expires_at) do
                        :lt ->
                            Flight.Date.standard_format(aircraft.registration_certificate_expires_at)

                        _ ->
                            "Expired"
                    end

            end

        insurance_status =
            case aircraft.insurance_expires_at do
                nil ->
                    "No insurance certificate."

                _ ->
                    case Date.compare(now, aircraft.insurance_expires_at) do
                        :lt ->
                            Flight.Date.standard_format(aircraft.insurance_expires_at)

                        _ ->
                            "Expired"
                    end
            end

        %{
            registration_cert_status: registration_cert_status,
            insurance_status: insurance_status
        }
    end
end
