defmodule Flight.SchedulingTest do
  use Flight.DataCase, async: true

  alias Flight.{Repo, Scheduling}
  alias Flight.Scheduling.{Aircraft, Inspection}

  describe "aircrafts" do
    @valid_attrs %{
      make: "make",
      model: "model",
      tail_number: "tail",
      serial_number: "serial",
      equipment: "equipment",
      ifr_certified: true,
      simulator: true,
      last_tach_time: 8000,
      rate_per_hour: 130,
      block_rate_per_hour: 120
    }

    test "create_aircraft/1 returns aircraft" do
      assert {:ok, %Aircraft{} = aircraft} = Scheduling.create_aircraft(@valid_attrs)

      assert aircraft.make == "make"
      assert aircraft.model == "model"
      assert aircraft.tail_number == "tail"
      assert aircraft.serial_number == "serial"
      assert aircraft.ifr_certified == true
      assert aircraft.simulator == true
      assert aircraft.last_tach_time == 8000
      assert aircraft.rate_per_hour == 130
      assert aircraft.block_rate_per_hour == 120
      assert aircraft.equipment == "equipment"
    end

    test "create_aircraft/1 creates default inspections" do
      assert {:ok, %Aircraft{} = aircraft} = Scheduling.create_aircraft(@valid_attrs)

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "Annual",
               type: "date"
             )

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "Transponder",
               type: "date"
             )

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "Altimeter",
               type: "date"
             )

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "ELT",
               type: "date"
             )

      assert Repo.get_by(
               Inspection,
               aircraft_id: aircraft.id,
               name: "100hr",
               type: "tach"
             )
    end

    test "create_aircraft/1 returns error" do
      assert {:error, _} = Scheduling.create_aircraft(%{})
    end

    test "get_aircraft/1 gets aircraft" do
      aircraft = aircraft_fixture()

      assert %Aircraft{} = Scheduling.get_aircraft(aircraft.id)
    end

    test "visible_aircrafts/0 gets aircrafts" do
      aircraft_fixture()
      aircraft_fixture()
      assert [%Aircraft{}, %Aircraft{}] = Scheduling.visible_aircrafts()
    end

    test "update_aircraft/2 updates" do
      aircraft = aircraft_fixture()

      assert {:ok, %Aircraft{make: "New Model"}} =
               Scheduling.update_aircraft(aircraft, %{make: "New Model"})
    end
  end

  describe "inspections" do
    @valid_attrs %{
      name: "Some New Name",
      aircraft_id: 3,
      expiration: "3/3/2018"
    }

    test "create_date_inspection/1 creates inspection" do
      aircraft = aircraft_fixture()

      {:ok, _inspection} =
        Scheduling.create_date_inspection(%{@valid_attrs | aircraft_id: aircraft.id})

      assert Flight.Repo.get_by(
               Inspection,
               name: "Some New Name",
               aircraft_id: aircraft.id,
               date_value: "3/3/2018"
             )
    end

    test "create_date_inspection/1 fails and returns correct changeset" do
      aircraft = aircraft_fixture()

      {:error, changeset} =
        Scheduling.create_date_inspection(%{
          @valid_attrs
          | expiration: "3/3/201",
            aircraft_id: aircraft.id
        })

      assert Enum.count(errors_on(changeset).expiration) > 0
    end

    test "update_inspection/2 updates date inspection" do
      inspection = date_inspection_fixture()

      {:ok, _inspection} = Scheduling.update_inspection(inspection, %{name: "Somethin' crazy"})

      assert Flight.Repo.get_by(
               Inspection,
               name: "Somethin' crazy"
             )
    end

    @tag :wip
    test "update_inspection/2 updates tach inspection" do
      inspection = tach_inspection_fixture()

      {:ok, _inspection} = Scheduling.update_inspection(inspection, %{name: "Somethin' crazy"})

      assert Flight.Repo.get_by(
               Inspection,
               name: "Somethin' crazy"
             )
    end

    test "update_inspection/2 update fails date" do
      inspection = date_inspection_fixture()

      {:error, changeset} = Scheduling.update_inspection(inspection, %{name: nil})

      assert Enum.count(errors_on(changeset).name) > 0
    end
  end
end
