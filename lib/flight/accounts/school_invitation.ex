defmodule Flight.Accounts.SchoolInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "school_invitations" do
    field(:accepted_at, :naive_datetime)
    field(:email, :string)
    field(:token, :string)
    field(:first_name, :string)
    field(:last_name, :string)

    timestamps()
  end

  @doc false
  def create_changeset(school_invitation, attrs) do
    school_invitation
    |> cast(attrs, [:email, :first_name, :last_name])
    |> generate_token()
    |> downcase_email()
    |> validate_required([:email, :first_name, :last_name, :token])
    |> unique_constraint(:token)
  end

  def accept_changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:accepted_at])
    |> validate_required([:accepted_at])
  end

  def generate_token(changeset) do
    put_change(changeset, :token, get_field(changeset, :token) || Flight.Random.hex(50))
  end

  def downcase_email(changeset) do
    email = get_field(changeset, :email)

    changeset
    |> Pipe.pass_unless(email, &put_change(&1, :email, String.downcase(email)))
  end

  def user_create_changeset(invitation) do
    Flight.Accounts.User.create_changeset(%Flight.Accounts.User{}, %{
      email: invitation.email,
      first_name: invitation.first_name,
      last_name: invitation.last_name
    })
  end
end