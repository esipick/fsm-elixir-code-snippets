defmodule Fsm.IonicAppVersion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ionic_app_versions" do
    field(:version, :string)
    field(:int_version, :integer)
    timestamps([inserted_at: :created_at])
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:version, :int_version])
    |> validate_required([:version, :int_version])
  end
end
