defmodule Flight.ScheudlingTest do
  use Flight.DataCase, async: true

  alias Flight.Scheduling
  alias Flight.Scheduling.{Aircraft}

  describe "aircrafts" do
    test "create_aircraft/1 returns aircraft" do
      assert {:ok, %Aircraft{} = aircraft} =
               Scheduling.create_aircraft(%{
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
               })

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
end
