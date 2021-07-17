defmodule Fsm.Aircrafts.Engine do
    use Ecto.Schema
    import Ecto.Changeset
  
    schema "aircraft_engines" do
      field :engine_make, :string
      field :engine_model, :string
      field :engine_serial, :string
      field :engine_tach_start, :float
      field :engine_hobbs_start, :float
      field :is_tachometer, :boolean
      field :engine_position, EnginePosition
  
      belongs_to :aircraft, Fsm.Scheduling.Aircraft
  
      timestamps()
    end
  
    def changeset(engine, attrs) do
      engine
      |> cast(attrs, [:engine_make, :engine_model, :engine_serial, :engine_tach_start, :engine_hobbs_start, :aircraft_id, :is_tachometer, :engine_position])
    end
  end
  