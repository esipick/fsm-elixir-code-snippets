defmodule Flight.Accounts.FlyerCertificate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "flyer_certificates" do
    field(:slug, :string)

    timestamps()
  end

  @doc false
  def changeset(flyer_certificate, attrs) do
    flyer_certificate
    |> cast(attrs, [:slug])
    |> validate_required([:slug])
  end
end
