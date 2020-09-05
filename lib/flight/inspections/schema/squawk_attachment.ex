defmodule Flight.Inspections.SquawkAttachment do
    use Ecto.Schema
    import Ecto.Changeset
    use Waffle.Ecto.Schema

    alias Flight.Inspections.{
        Squawk,
        SquawkAttachment
    }
    
    alias Flight.SquawksUploader

    @allowed_file_types ["image/png", "image/jpeg"]

    schema "squawk_attachments" do
        field(:attachment, SquawksUploader.Type)

        belongs_to(:squawk, Squawk, type: :binary_id)

        timestamps([inserted_at: :created_at])
    end 

    defp required_fields(), do: ~w(attachment squawk_id)a

    def changeset(%SquawkAttachment{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, (__MODULE__.__schema__(:fields) -- [:attachment]))
        |> cast_attachments(params, [:attachment])
        |> validate_required(required_fields())
        |> validate_type(params)
        |> validate_file_size(params)
    end

    defp validate_file_size(changeset, %{attachment: attachment}) do
        {:ok, %{size: size}} = File.stat(attachment.path)
    
        file_size = Application.get_env(:flight, :file_size, 5_000_000)
        human_size = Size.humanize!(file_size, spacer: "")
    
        case size > file_size do
          true -> add_error(changeset, :file, "size should not exceed #{human_size}")
          false -> changeset
        end
      end
    
    defp validate_type(changeset, %{attachment: attachment}) do
        case Enum.member?(@allowed_file_types, attachment.content_type) do
          true -> changeset
          false -> add_error(changeset, :attachment, "Should be \".jpg .png\" type.")
        end
    end
end