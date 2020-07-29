defmodule Flight.Inspections.MaintenanceAlert do
    use Ecto.Schema
    import Ecto.Changeset

    alias Flight.Inspections.{
        Maintenance,
        MaintenanceAlert
    }

    @roles ["admin", "dispatcher", "instructor", "mechanic", "student"]

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "maintenance_alerts" do
        field(:name, :string, null: true)
        field(:description, :string, null: false)

        field(:send_alert_percentage, :integer, default: 0)

        field(:send_to_roles, {:array, :string}, null: false)

        field(:maintenance_id, :binary_id, null: false)
        belongs_to(:maintenance, Maintenance, define_field: false, foreign_key: :maintenance_id)

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(description send_to_roles maintenance_id)a

    def changeset(%MaintenanceAlert{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
        |> validate_role_inclusion()
    end

    defp validate_role_inclusion(%Ecto.Changeset{valid?: true, changes: %{send_to_roles: roles}} = changeset) do
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