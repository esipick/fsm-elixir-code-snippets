defmodule Fsm.Aircrafts.DefaultInspections do
    alias Fsm.Scheduling.Aircraft
    alias Fsm.Aircrafts.Inspection
    alias Fsm.Aircrafts.InspectionData

    def seed(dynamic_attrs \\ %{}) do
        [
            %Inspection{
                name: "ELT Check",
                type: "VFR",
                updated: false,
                is_completed: false,
                date_tach: :date,
                is_system_defined: true,
                inspection_data: [
                    last_inspection(1),
                    next_inspection(2),
                    last_tach_time(3),
                    last_hobbs_time(4)
                ]
            } |> Map.merge(dynamic_attrs),
            %Inspection{
                name: "Transponder",
                type: "VFR",
                updated: false,
                is_completed: false,
                date_tach: :date,
                is_system_defined: true,
                inspection_data: [
                    last_inspection(1),
                    next_inspection(2),
                    last_tach_time(3),
                    last_hobbs_time(4)
                ]
            } |> Map.merge(dynamic_attrs),
            %Inspection{
                name: "100 Hr Inspection",
                type: "VFR",
                updated: false,
                is_completed: false,
                date_tach: :tach,
                is_system_defined: true,
                inspection_data: [
                    last_inspection(1),
                    last_tach_time(2),
                    next_tach_time(3),
                    last_hobbs_time(4)
                ]
            } |> Map.merge(dynamic_attrs),
            %Inspection{
                name: "Static System",
                type: "VFR",
                updated: false,
                is_completed: false,
                date_tach: :date,
                is_system_defined: true,
                inspection_data: [
                    last_inspection(1),
                    next_inspection(2),
                    last_tach_time(3),
                    last_hobbs_time(4),
                ]
            } |> Map.merge(dynamic_attrs),
            %Inspection{
                name: "Annual",
                type: "VFR",
                updated: false,
                is_completed: false,
                date_tach: :date,
                is_system_defined: true,
                inspection_data: [
                    last_inspection(1),
                    next_inspection(2),
                    last_tach_time(3),
                    last_hobbs_time(4)
                ]
            } |> Map.merge(dynamic_attrs),
            %Inspection{
                name: "Nav Database",
                type: "IFR",
                updated: false,
                is_completed: false,
                date_tach: :date,
                is_system_defined: true,
                inspection_data: [
                    last_inspection(1),
                    next_inspection(2)
                ]
            } |> Map.merge(dynamic_attrs),
            %Inspection{
                name: "VOR Check",
                type: "IFR",
                updated: false,
                is_completed: false,
                date_tach: :date,
                is_system_defined: true,
                inspection_data: [
                    current_date(1),
                    next_inspection(2),
                    str_field("Method(Duel, VOT, Airborne)", 3),
                    str_field("Frequency", 4),
                    str_field("Position", 5),
                    str_field("Bearing Error", 6),
                    str_field("Pilots Name", 7),
                    str_field("Pilot Signature", 8)
                ]
            } |> Map.merge(dynamic_attrs),
            %Inspection{
                name: "Altimeter",
                type: "IFR",
                updated: false,
                is_completed: false,
                date_tach: :date,
                is_system_defined: true,
                inspection_data: [
                    last_inspection(1),
                    next_inspection(2),
                    last_tach_time(3),
                    last_hobbs_time(4)
                ]
            } |> Map.merge(dynamic_attrs)
        ]
    end

    defp last_inspection(sort) do
        %InspectionData{}
        |> InspectionData.changeset(%{name: "Last Inspection", value: "", type: :date, class_name: "last_inspection", sort: sort})
    end

    defp next_inspection(sort) do
        %InspectionData{name: "Next Inspection", value: "", type: :date, class_name: "next_inspection", sort: sort}
    end

    defp last_tach_time(sort) do
        %InspectionData{name: "Last Inspection Tach Time", value: "",class_name: "last_inspection", type: :float, sort: sort}
    end

    defp last_hobbs_time(sort) do
        %InspectionData{name: "Last Inspection Hobbs Time", value: "", type: :float, sort: sort}
    end

    defp next_tach_time(sort) do
        %InspectionData{name: "Next Inspection Tach Time", value: "",class_name: "next_inspection", type: :float, sort: sort}
    end

    defp next_hobbs_time(sort) do
        %InspectionData{name: "Next Inspection Hobbs Time", value: "", type: :float, sort: sort}
    end

    defp current_date(sort) do
        %InspectionData{name: "Current Date", value: "", type: :date, sort: sort}
    end

    defp str_field(name, sort) do
        %InspectionData{name: name, value: "", type: :string, sort: sort}
    end
end