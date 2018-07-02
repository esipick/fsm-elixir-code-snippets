defmodule Flight.Repo.Migrations.CreateInstructorLineItemDetails do
  use Ecto.Migration

  def change do
    create table(:instructor_line_item_details) do
      add(:hour_tenths, :integer)
      add(:billing_rate, :integer)
      add(:pay_rate, :integer)
      add(:transaction_line_item_id, references(:transaction_line_items, on_delete: :nothing))
      add(:instructor_user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:instructor_line_item_details, [:instructor_user_id]))
    create(index(:instructor_line_item_details, [:transaction_line_item_id]))
  end
end
