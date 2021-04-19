defmodule Fsm.Dashboard do

  alias Fsm.{Accounts, Scheduling}

  alias Flight.Repo
  alias Fsm.IonicAppVersion

  import Ecto.Query, warn: false
  ##
  # List Roles Count Stats
  ##
  def list_roles_counts(context) do
    student_count = Accounts.get_user_count(Accounts.Role.student(), context)
    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), context)
    renter_count = Accounts.get_user_count(Accounts.Role.renter(), context)
    aircrafts = Scheduling.visible_air_assets(context)

    [
      %{
        title: "STUDENTS",
        count: student_count
      },
      %{
        title: "INSTRUCTORS",
        count: instructor_count
      },
      %{
        title: "RENTERS",
        count: renter_count
      },
      %{
        title: "AIRCRAFTS",
        count: Enum.count(aircrafts)
      }
    ]
  end

  ##
  # Latest Ionic App version
  ##
  def latest_app_version do
    get_latest_app_version()
#    validate_version(version)
#    |> case do
#         {:ok, int_version} -> {:ok, Map.put(version_map, :int_version, int_version)}
#         error -> error
#       end
  end
#require Logger
#  def validate_version(version) do
#    parts =
#      version
#      |> String.split(".", trim: true)
#      |> Enum.take(3)
#
#      Logger.info fn -> "{version, parts}: #{inspect {version, parts}}" end
#
#    int_version(parts, Enum.count(parts))
#  end
#
#  defp int_version(parts, parts_count) when parts_count == 3 do
#
#    Enum.reduce_while(parts, {:ok, ""}, fn part, {:ok, acc} ->
#      part
#      |> normalize_part(String.length(part))
#      |> case do
#           {:ok, part} -> {:cont, {:ok, acc <> part}}
#           {:error, error} -> {:halt, {:error, error}}
#         end
#    end)
#    |> case do
#         {:ok, num} ->
#           {int_version, _} = Integer.parse(num)
#           {:ok, int_version}
#
#         error -> error
#       end
#  end
#
#  defp int_version(version, _), do: {:error, "invalid version: #{Enum.join(version, ".")}. version should be in xxx.yyy.zzz format, where x, y, z are numbers."}
#
#  defp normalize_part(part, part_count) when part_count > 0 and part_count <= 3 do
#    part
#    |> String.pad_leading(3, "0")
#    |> Integer.parse
#    |> case do
#         {_, ""} -> {:ok, String.pad_leading(part, 3, "0")}
#         _ -> {:error, "Version format is not valid. version should be in xxx.yyy.zzz format, where x, y, z are numbers."}
#       end
#  end
#  defp normalize_part(_part, _part_count), do: {:error, "Version format is not valid. version should be in xxx.yyy.zzz format, where x, y, z are numbers."}

  ##
  # Get Latest App version
  ##
  def get_latest_app_version do
      Ecto.Query.from(v in IonicAppVersion, order_by: [desc: v.created_at], limit: 1)
      |> Ecto.Query.first
      |> Repo.one() || %{version: "4.0.28", int_version: 4000028, android_version: "4.0.28", android_int_version: 4000028, ios_version: "4.0.28", ios_int_version: 4000028, created_at: "2020-01-28 22:00:00", updated_at: "2020-01-28 22:00:00"}
  end

#  ##
#  # List Other Stats
#  ##
#  def list_other_dashboard_stats_counts(conn, _params) do
#    student_count = Accounts.get_user_count(Accounts.Role.student(), conn)
#    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), conn)
#    renter_count = Accounts.get_user_count(Accounts.Role.renter(), conn)
#    aircrafts = Scheduling.visible_air_assets(conn)
#
#    fsm_income = Billing.platform_income()
#
#    expired_inspections = Flight.Scheduling.ExpiredInspection.inspections_for_aircrafts(aircrafts)
#
#    pending_transactions =
#      Flight.Billing.get_filtered_transactions(%{"state" => "pending"}, conn)
#      |> Flight.Repo.preload([:user])
#
#    total_pending =
#      pending_transactions
#      |> Enum.map(& &1.total)
#      |> Enum.sum()
#
#    %{
#      expired_inspections: expired_inspections,
#      pending_transactions: pending_transactions,
#      fsm_income: fsm_income,
#      total_pending: total_pending
#    }
#  end

#  ##
#  # List Appointments
#  ##
#  def list_roles_counts(conn, _params) do
#    student_count = Accounts.get_user_count(Accounts.Role.student(), conn)
#    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), conn)
#    renter_count = Accounts.get_user_count(Accounts.Role.renter(), conn)
#    aircrafts = Scheduling.visible_air_assets(conn)
#
#    fsm_income = Billing.platform_income()
#
#    expired_inspections = Flight.Scheduling.ExpiredInspection.inspections_for_aircrafts(aircrafts)
#
#    pending_transactions =
#      Flight.Billing.get_filtered_transactions(%{"state" => "pending"}, conn)
#      |> Flight.Repo.preload([:user])
#
#    total_pending =
#      pending_transactions
#      |> Enum.map(& &1.total)
#      |> Enum.sum()
#
#    %{
#      student_count: student_count,
#      instructor_count: instructor_count,
#      renter_count: renter_count,
#      aircraft_count: Enum.count(aircrafts),
#      expired_inspections: expired_inspections,
#      pending_transactions: pending_transactions,
#      fsm_income: fsm_income,
#      total_pending: total_pending
#    }
#  end
end
