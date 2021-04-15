defmodule Flight.Accounts.UserAircraft do
    use Ecto.Schema
    import Ecto.Changeset
    alias Flight.Accounts.User
    alias Flight.Accounts.UserAircraft
    
    schema "user_aircrafts" do
        belongs_to :user, User, foreign_key: :user_id
        belongs_to :aircraft, User, foreign_key: :aircraft_id
    end

    def changeset(%UserAircraft{} = changeset, attrs) do
        changeset
        |> cast(attrs, [:user_id, :aircraft_id])
        |> validate_required([:user_id, :aircraft_id])
    end
end