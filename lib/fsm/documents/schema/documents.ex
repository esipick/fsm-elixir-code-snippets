defmodule Fsm.Schema.Document do
    use Ecto.Schema
    use Waffle.Ecto.Schema
  
    require Ecto.Query
    import Ecto.Query
    import Flight.Repo
    import Ecto.Changeset
  
    alias __MODULE__
    alias Ecto.Multi
    alias Flight.DocumentUploader
  
    @allowed_file_types ["image/png", "image/jpeg", "application/pdf"]
  
    schema "documents" do
      field(:expires_at, :date)
      field(:title, :string)
      field(:file, DocumentUploader.Type)
      belongs_to(:user, Flight.Accounts.User)
  
      timestamps()
    end
  
    def changeset(document \\ %Document{}, attrs) do
      document
      |> cast(attrs, [:expires_at, :title, :user_id])
      |> validate_required([:user_id])
    end
  
    def file_changeset(document, attrs) do
      document
      |> cast_attachments(attrs, [:file])
      |> validate_type(attrs)
      |> validate_file_size(attrs)
      |> validate_required([:file])
    end
  
    defp validate_file_size(document, %{"file" => file}) do
      {:ok, %{size: size}} = File.stat(file.path)
  
      file_size = Application.get_env(:flight, :file_size, 5_242_880)
      human_size = Size.humanize!(file_size, spacer: "")
  
      case size > file_size do
        true -> add_error(document, :file, "size should not exceed #{human_size}")
        false -> document
      end
    end
  
    defp validate_type(document, %{"file" => file}) do
      case Enum.member?(@allowed_file_types, file.content_type) do
        true -> document
        false -> add_error(document, :file, "Should be \".jpg .pdf .png\" type.")
      end
    end
  end
  