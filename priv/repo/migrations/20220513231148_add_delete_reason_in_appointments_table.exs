defmodule Flight.Repo.Migrations.AddDeleteReasonInAppointmentsTable do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add :delete_reason, :string
      add :delete_reason_options, {:array, :string}
    end
  end
end
