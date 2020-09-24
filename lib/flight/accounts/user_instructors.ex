defmodule Flight.Accounts.UserInstructor do
    use Ecto.Schema

    alias Flight.Accounts.User
    
    schema "user_instructors" do
        belongs_to :user, User, foreign_key: :user_id
        belongs_to :instructor, User, foreign_key: :instructor_id
    end
end