defmodule Fsm.Aircrafts.InspectionNotesAuditTrail do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.SoftDelete.Schema

  alias Fsm.Aircrafts.Inspection
  alias Fsm.Aircrafts.InspectionNotesAuditTrail

  schema "inspection_notes_audit_trail" do
    field(:notes, :string)

    belongs_to(:user, Fsm.Accounts.User)
    belongs_to(:inspection, Inspection)

    soft_delete_schema()
    timestamps()
  end

  defp required_fields(), do: ~w(user_id inspection_id)a

  def changeset(%InspectionNotesAuditTrail{} = changeset, params \\ %{}) do
    changeset
    |> cast(params, (__MODULE__.__schema__(:fields)))
    |> validate_required(required_fields())
  end
end
