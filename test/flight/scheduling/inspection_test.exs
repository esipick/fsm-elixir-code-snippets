defmodule Flight.Scheduling.InspectionTest do
  use Flight.DataCase, async: true

  alias Flight.Scheduling.{Inspection, DateInspection, TachInspection}

  describe "Inspection changeset" do
    test "date validation passes" do
      assert Inspection.changeset(%Inspection{}, %{
               type: "date",
               date_value: Date.add(Date.utc_today(), 1),
               aircraft_id: 3,
               name: "Annual"
             }).valid?
    end

    test "date validation passes if using text date" do
      assert Inspection.changeset(%Inspection{}, %{
               type: "date",
               date_value: "3/3/2038",
               aircraft_id: 3,
               name: "Annual"
             }).valid?
    end

    test "date validation fails if number_value is set" do
      refute Inspection.changeset(%Inspection{}, %{
               type: "date",
               number_value: 300,
               aircraft_id: 3,
               name: "Annual"
             }).valid?
    end

    test "tach validation passes" do
      assert Inspection.changeset(%Inspection{}, %{
               type: "tach",
               number_value: 300,
               aircraft_id: 3,
               name: "Annual"
             }).valid?
    end

    test "tach validation fails if number_value is set" do
      refute Inspection.changeset(%Inspection{}, %{
               type: "tach",
               date_value: Date.add(Date.utc_today(), 1),
               aircraft_id: 3,
               name: "Annual"
             }).valid?
    end

    test "to_specific DateInspection" do
      date = Date.add(Date.utc_today(), 1)
      inspection = date_inspection_fixture(%{expiration: date})

      date_inspection = Inspection.to_specific(inspection)
      assert DateInspection.changeset(date_inspection, %{}).valid?
      assert date_inspection.aircraft_id == inspection.aircraft.id
      assert date_inspection.id == inspection.id
      assert date_inspection.name == inspection.name
    end

    test "to_specific TachInspection" do
      inspection = tach_inspection_fixture(%{tach_time: 300})

      tach_inspection = Inspection.to_specific(inspection)
      assert TachInspection.changeset(tach_inspection, %{}).valid?
      assert tach_inspection.aircraft_id == inspection.aircraft.id
      assert tach_inspection.id == inspection.id
      assert tach_inspection.name == inspection.name
    end
  end

  describe "DateInspection changeset" do
    test "valid changeset" do
      DateInspection.changeset(%DateInspection{}, %{expiration: "3/3/2018"}).valid?
    end

    test "invalid changeset" do
      DateInspection.changeset(%DateInspection{}, %{expiration: nil}).valid?
    end

    test "attrs applied to inspection is valid" do
      date_inspection = %DateInspection{
        expiration: "3/3/2018",
        aircraft_id: 3,
        name: "Annual"
      }

      {:ok, inspection} =
        %Inspection{}
        |> Inspection.changeset(DateInspection.attrs(date_inspection))
        |> apply_action(:insert)

      assert inspection.type == "date"
      assert inspection.aircraft_id == 3
      assert inspection.name == "Annual"
      assert Inspection.changeset(inspection, %{}).valid?
    end
  end

  describe "TachInspection changeset" do
    test "valid changeset" do
      TachInspection.changeset(%TachInspection{}, %{tach_time: 3}).valid?
    end

    test "invalid changeset" do
      TachInspection.changeset(%TachInspection{}, %{tach_time: nil}).valid?
    end

    test "attrs applied to inspection is valid" do
      tach_inspection = %TachInspection{tach_time: 300, aircraft_id: 3, name: "Annual"}

      {:ok, inspection} =
        %Inspection{}
        |> Inspection.changeset(TachInspection.attrs(tach_inspection))
        |> apply_action(:insert)

      assert inspection.type == "tach"
      assert inspection.aircraft_id == 3
      assert inspection.name == "Annual"
      assert Inspection.changeset(inspection, %{}).valid?
    end
  end
end
