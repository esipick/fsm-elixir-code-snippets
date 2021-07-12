defmodule Fsm.Squawks.Squawk do
    use Ecto.Schema
    import Ecto.Changeset
    import Ecto.SoftDelete.Schema
    alias Fsm.Accounts.User
    alias Fsm.Aircrafts.Aircraft
    
    schema "squawks" do
      field :title, :string
      field :severity, SquawkSeverity
      field :system_affected, SystemAffected
      field :description, :string
      field :resolved, :boolean
      has_many(:attachments, Fsm.Attachments.Attachment)
      belongs_to(:user, User)
      belongs_to(:aircraft, Aircraft)
  
      soft_delete_schema()
      timestamps()
    end
  
    @doc false
    def changeset(squawk, attrs) do
      squawk
      |> cast(attrs, [:title, :severity, :description, :resolved,:system_affected, :user_id])
    end
end