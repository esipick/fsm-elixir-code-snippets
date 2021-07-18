defmodule Fsm.Attachments.Attachment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.SoftDelete.Schema
  alias Fsm.Accounts.User
  
  schema "attachments" do
    field :url, :string
    field :file_name, :string
    field :file_extension, :string
    field :size_in_bytes, :integer
    field :expiration_date, :naive_datetime
    field :document_type, DocumentType
    field :attachment_type, AttachmentType
    belongs_to(:inspection, Fsm.Aircrafts.Inspection)
    belongs_to(:squawk, Fsm.Squawks.Squawk)
    belongs_to(:user, User)

    soft_delete_schema()
    timestamps()
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:url, :file_name, :file_extension, :size_in_bytes, :inspection_id, :squawk_id, :document_type, :attachment_type, :user_id, :expiration_date])
    |> validate_required([:url, :file_name, :file_extension, :size_in_bytes])
  end
end
