defmodule Flight.Notifications.PushToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "push_tokens" do
    field(:endpoint_arn, :string)
    field(:platform, :string)
    field(:token, :string)
    belongs_to(:user, Flight.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(push_token, attrs) do
    push_token
    |> cast(attrs, [:endpoint_arn, :token, :platform, :user_id])
    |> validate_required([:endpoint_arn, :token, :platform, :user_id])
    |> validate_inclusion(:platform, ["ios", "android"])
  end
end
