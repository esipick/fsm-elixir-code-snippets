defmodule Flight.Accounts.PasswordReset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "password_resets" do
    field(:token, :string)
    belongs_to(:user, Flight.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(password_reset, attrs) do
    password_reset
    |> cast(attrs, [:token, :user_id])
    |> validate_required([:token, :user_id])
  end
end
