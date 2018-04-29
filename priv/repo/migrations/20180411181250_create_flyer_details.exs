defmodule Flight.Repo.Migrations.CreateFlyerDetails do
  use Ecto.Migration

  def change do
    create table(:flyer_details) do
      add(:address_1, :text)
      add(:city, :text)
      add(:state, :text)
      add(:faa_tracking_number, :text)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(unique_index(:flyer_details, [:user_id]))
  end
end
