defmodule Fsm.Aircrafts.Inspection do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.SoftDelete.Schema

  schema "inspections" do
      field :name, :string
      field :type, :string
      field :updated, :boolean, default: false
      field :is_completed, :boolean, default: false
      field :note, :string
      field :is_repeated, :boolean
      field :repeat_every_days, :integer
      field :date_tach, DateTachEnum
      field :is_notified, :boolean, default: false
      field :is_email_notified, :boolean, default: false
      field :is_system_defined, :boolean
      field :completed_at, :naive_datetime

      field :tach_hours, :float, virtual: true
      field :last_inspection, InspectionDataType, virtual: true
      field :next_inspection, InspectionDataType, virtual: true


      belongs_to :aircraft, Fsm.Scheduling.Aircraft
      has_many(:inspection_data, Fsm.Aircrafts.InspectionData)
      has_many(:attachments, Fsm.Attachments.Attachment)
      belongs_to(:aircraft_engine, Fsm.Aircrafts.Engine)
      belongs_to(:user, Fsm.Accounts.User)

      soft_delete_schema()
      timestamps()
  end

  @doc false
  def changeset(inspection, attrs) do
      inspection
      |> cast(attrs, [:name,:type, :updated, :is_completed, :aircraft_id, :date_tach, :is_repeated, :repeat_every_days, :is_notified, :is_email_notified, :is_system_defined, :aircraft_engine_id, :user_id, :completed_at])
      |> validate_required([:name,:type, :aircraft_id])
      |> cast_assoc(:inspection_data)
  end

  def new_changeset() do
    changeset(%Fsm.Aircrafts.Inspection{}, %{})
  end

end