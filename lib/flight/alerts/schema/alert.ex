defmodule Flight.Alerts.Alert do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Alerts.Alert
    alias Flight.Accounts.{
        School,
        User
    }

    schema "alerts" do
        field(:code, AlertCodeEnum, default: :appointment)
        field(:title, :string, null: true)
        field(:description, :string, null: true)

        field(:priority, AlertPriorityEnum, default: :low)

        field(:receiver_id, :id, null: true) # if receiver_id is null this is a broadcast alert. The school id should be non nil for broadcast alert.
        field(:sender_id, :id, null: true)

        field(:is_read, :boolean, default: false)

        field(:archived, :boolean, default: false)

        field(:additional_info, :map, null: true)

        belongs_to(:school, School)
        belongs_to(:receiver, User, define_field: false, foreign_key: :receiver_id)
        belongs_to(:sender, User, define_field: false, foreign_key: :sender_id)

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(school_id)a

    def changeset(%Alert{} = alert, attrs \\ %{}) do
        alert
        |> cast(attrs, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
    end
end
