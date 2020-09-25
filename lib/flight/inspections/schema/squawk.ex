defmodule Flight.Inspections.Squawk do
    use Ecto.Schema
    import Ecto.Changeset
    
    alias Flight.Inspections.{
        Squawk,
        SquawkAttachment
    }

    alias Flight.Scheduling.Aircraft

    alias Flight.Accounts.{
        School,
        User
    }

    @roles ["admin", "dispatcher", "mechanic"]

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "squawks" do
        field(:description, :string, null: false)
        field(:severity, SquawkSeverityEnum, default: :ground)
        
        field(:reported_at, :naive_datetime, default: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second))
        field(:resolved_at, :naive_datetime)

        field(:reported_by_id, :id, null: false)
        field(:created_by_id, :id, null: false)

        field(:notify_roles, {:array, :string}, null: true)
        field(:notes, :string, null: true)

        belongs_to(:school, School)
        belongs_to(:aircraft, Aircraft)
        has_many(:attachments, SquawkAttachment)
        belongs_to(:reported_by, User, define_field: false, foreign_key: :reported_by_id)
        belongs_to(:created_by, User, define_field: false, foreign_key: :created_by_id)

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(description reported_by_id created_by_id school_id aircraft_id)a

    def changeset(%Squawk{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
        |> validate_role_inclusion()
    end

    defp validate_role_inclusion(%Ecto.Changeset{valid?: true, changes: %{notify_roles: nil}} = changeset), do: changeset
    defp validate_role_inclusion(%Ecto.Changeset{valid?: true, changes: %{notify_roles: roles}} = changeset) do
        roles = 
            Enum.reduce_while(roles, changeset, fn (role, changeset) -> 
                norm_role = role || ""

                if norm_role in @roles do
                    {:cont, changeset}
                else
                    {:halt, add_error(changeset, :send_to_role, "#{inspect role} is not a valid role")}
                end
            end)
    end

    defp validate_role_inclusion(changeset), do: changeset
end