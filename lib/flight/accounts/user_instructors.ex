defmodule Flight.Accounts.UserInstructor do
    use Ecto.Schema
    import Ecto.Changeset
    alias Flight.Accounts.User
    alias Flight.Accounts.UserInstructor
    
    schema "user_instructors" do
        belongs_to :user, User, foreign_key: :user_id
        belongs_to :instructor, User, foreign_key: :instructor_id
    end

    def changeset(%UserInstructor{} = changeset, attrs) do
        changeset
        |> cast(attrs, [:user_id, :instructor_id])
        |> validate_required([:user_id, :instructor_id])
    end
end