defmodule Flight.Accounts.UserFlyerCertificate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_flyer_certificates" do
    field(:user_id, :id)
    field(:flyer_certificate_id, :id)
  end

  @doc false
  def changeset(user_flyer_certificate, attrs) do
    user_flyer_certificate
    |> cast(attrs, [])
    |> validate_required([])
  end
end
