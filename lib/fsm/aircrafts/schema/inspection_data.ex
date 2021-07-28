defmodule Fsm.Aircrafts.InspectionData do
    use Ecto.Schema
    import Ecto.Changeset
    require Logger

    schema "inspection_data" do
        field :name, :string        
        field :class_name, :string
        field :type, InspectionDataType
        field :sort, :integer
        field :t_int, :integer
        field :t_str, :string
        field :t_float, :float
        field :t_date, :date
        belongs_to :inspection, Fsm.Aircrafts.Inspection

        field :value, :string, virtual: true
    end

    @doc false
    def changeset(inspection, attrs) do
        inspection
        |> cast(attrs, [:name, :value, :class_name, :type, :sort, :inspection_id, :t_int, :t_str, :t_float, :t_date])
        |> validate_required([:name, :type])
    end

    def value_from_t_field(%{t_int: t_int, t_str: t_str, t_float: t_float, t_date: t_date} = params) do
        cond do
            t_int != nil ->
                t_int
            t_str != nil ->
                t_str
            t_float != nil ->
                t_float
            t_date != nil ->
                t_date
            true ->
                nil
        end
    end
end