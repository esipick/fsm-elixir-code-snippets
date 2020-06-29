defmodule Flight.IosAppVersion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ios_app_versions" do
    field(:version, :string)
    timestamps([inserted_at: :created_at])
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:version])
    |> validate_required([:version])
  end
end
