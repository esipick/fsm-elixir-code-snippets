defmodule Flight.Accounts.Invitation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "invitations" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:token, :string)
    field(:accepted_at, :naive_datetime)
    belongs_to(:role, Flight.Accounts.Role)

    timestamps()
  end

  @doc false
  def create_changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:first_name, :last_name, :email, :role_id])
    |> generate_token()
    |> downcase_email()
    |> validate_required([:first_name, :last_name, :email, :role_id, :token])
    |> unique_constraint(:email, message: "already has an invitation.")
    |> unique_constraint(:token)
  end

  def accept_changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:accepted_at])
    |> validate_required([:accepted_at])
  end

  def downcase_email(changeset) do
    email = get_field(changeset, :email)

    changeset
    |> Pipe.pass_unless(email, &put_change(&1, :email, String.downcase(email)))
  end

  def generate_token(changeset) do
    put_change(changeset, :token, get_field(changeset, :token) || Flight.Random.hex(50))
  end

  def user_create_changeset(invitation) do
    Flight.Accounts.User.create_changeset(%Flight.Accounts.User{}, %{
      email: invitation.email,
      first_name: invitation.first_name,
      last_name: invitation.last_name
    })
  end
end
