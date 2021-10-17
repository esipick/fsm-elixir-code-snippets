defmodule Flight.Inspections.AircraftMaintenanceAttachment do
    use Ecto.Schema
    import Ecto.Changeset
    use Waffle.Ecto.Schema

    alias Flight.AircraftMaintenanceUploader
    alias Flight.Inspections.{
        AircraftMaintenance,
        AircraftMaintenanceAttachment
    }

    # @allowed_file_types ["image/png", "image/jpeg"]

    schema "aircraft_maintenance_attachments" do
        field(:title, :string, null: true)
        field(:attachment, AircraftMaintenanceUploader.Type)

        belongs_to(:aircraft_maintenance, AircraftMaintenance, type: :binary_id)

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(attachment aircraft_maintenance_id)a

    def changeset(%AircraftMaintenanceAttachment{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, (__MODULE__.__schema__(:fields) -- [:attachment]))
        |> cast_attachments(params, [:attachment])
        |> validate_required(required_fields())
        # |> validate_type(params)
        |> validate_file_size(params)
    end

    defp validate_file_size(changeset, %{attachment: attachment}) do
        {:ok, %{size: size}} = File.stat(attachment.path)
    
        file_size = Application.get_env(:flight, :file_size, 5_242_880)
        human_size = Size.humanize!(file_size, spacer: "")
    
        case size > file_size do
          true -> add_error(changeset, :file, "size should not exceed #{human_size}")
          false -> changeset
        end
      end
    
    # defp validate_type(changeset, %{attachment: attachment}) do
    #     case Enum.member?(@allowed_file_types, attachment.content_type) do
    #       true -> changeset
    #       false -> add_error(changeset, :attachment, "Should be \".jpg .png\" type.")
    #     end
    # end
end