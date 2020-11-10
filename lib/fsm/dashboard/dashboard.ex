defmodule Fsm.Dashboard do

  alias Fsm.{Accounts, Scheduling}

  alias Flight.Repo

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
