defmodule Flight.Scheduling.ExpiredInspectionTest do
  use Flight.DataCase, async: true

  alias Flight.Scheduling.ExpiredInspection

  describe "inspection_status" do
    test "returns good for date" do
      inspection = date_inspection_fixture(%{expiration: ~D[2038-04-03]})
      assert ExpiredInspection.inspection_status(inspection, ~D[2038-03-01]) == :good
    end

    test "returns expiring for date" do
      inspection = date_inspection_fixture(%{expiration: ~D[2038-03-03]})
      assert ExpiredInspection.inspection_status(inspection, ~D[2038-03-01]) == :expiring
    end

    test "returns expired for date" do
      inspection = date_inspection_fixture(%{expiration: ~D[2038-03-03]})
      assert ExpiredInspection.inspection_status(inspection, ~D[2038-03-05]) == :expired
    end

    test "returns good for tach" do
      aircraft = aircraft_fixture(%{last_tach_time: 3400})
      inspection = tach_inspection_fixture(%{tach_time: 3421}, aircraft)
      assert ExpiredInspection.inspection_status(inspection) == :good
    end

    test "returns expiring for tach" do
      aircraft = aircraft_fixture(%{last_tach_time: 3400})
      inspection = tach_inspection_fixture(%{tach_time: 3404}, aircraft)
      assert ExpiredInspection.inspection_status(inspection) == :expiring
    end

    test "returns expired for tach" do
      aircraft = aircraft_fixture(%{last_tach_time: 3400})
      inspection = tach_inspection_fixture(%{tach_time: 3399}, aircraft)
      assert ExpiredInspection.inspection_status(inspection) == :expired
    end
  end
end
