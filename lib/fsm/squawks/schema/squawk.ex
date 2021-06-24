defmodule Fboss.Squawks.Squawk do
    use Ecto.Schema
    import Ecto.Changeset
    import Ecto.SoftDelete.Schema
    alias Fsm.Accounts.User
    
    schema "squawks" do
      field :title, :string
      field :severity, SquawkSeverity
      field :system_affected, SystemAffected
      field :description, :string
      field :resolved, :boolean
    #   has_many(:attachments, Fboss.Attachments.Attachment)
      belongs_to(:user, User)
  
      soft_delete_schema()
      timestamps()
    end
  
    @doc false
    def changeset(squawk, attrs) do
      squawk
      |> cast(attrs, [:title, :severity, :description, :resolved,:system_affected, :user_id])
    end
end