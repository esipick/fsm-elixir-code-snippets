defmodule Flight.ReportTable do
  defstruct [:headers, :rows]

  def empty() do
    %Flight.ReportTable{
      headers: [],
      rows: []
    }
  end
end

defmodule Flight.Reports do
  alias Flight.{Repo}
  alias Flight.Accounts.{User, Role, UserRole}
  alias Flight.Scheduling.{Appointment}
  alias Flight.Billing.{Transaction}
  alias Flight.SchoolScope

  require Ecto.Query
  import Ecto.Query

  def student_report(from, to, school_context) when is_binary(from) and is_binary(to) do
    start_at = Timex.parse!(from, "{0M}-{0D}-{YYYY}")
    end_at = Timex.parse!(to, "{0M}-{0D}-{YYYY}")
    student_report(start_at, end_at, school_context)
  end

  def student_report(from, to, school_context) do
    start_at =
      from
      |> Timex.to_naive_datetime()

    end_at =
      to
      |> Timex.shift(days: 1)
      |> Timex.to_naive_datetime()

    role = Role.student()

    users =
      User
      |> SchoolScope.scope_query(school_context)
      |> join(:inner, [u], r in UserRole, r.user_id == u.id)
      |> where([u, r], r.role_id == ^role.id)
      |> Repo.all()

    user_ids = Enum.map(users, & &1.id)

    appointments =
      Appointment
      |> SchoolScope.scope_query(school_context)
      |> where([a], a.user_id in ^user_ids)
      |> where([a], a.start_at >= ^start_at and a.start_at < ^end_at)
      |> Repo.all()
      |> Enum.group_by(& &1.user_id)

    transactions =
      Transaction
      |> SchoolScope.scope_query(school_context)
      |> where([t], t.user_id in ^user_ids)
      |> where([t], t.state == "completed")
      |> where([t], t.completed_at >= ^start_at and t.completed_at < ^end_at)
      |> Repo.all()
      |> Repo.preload(line_items: [:aircraft_detail, :instructor_detail])
      |> Enum.group_by(& &1.user_id)

    rows =
      users
      |> Enum.map(fn user ->
        [
          "#{user.first_name} #{user.last_name}",
          num_appointments(user, appointments),
          time_flown(user, transactions),
          time_instructed(user, transactions),
          income_generated(user, transactions),
          credit_given(user, transactions),
          deducted_from_balance(user, transactions)
        ]
      end)

    %Flight.ReportTable{
      headers: [
        "Name",
        "# of Appointments",
        "Time Flown",
        "Time Instructed",
        "Income Generated",
        "Credit Given",
        "Deducted from Balance"
      ],
      rows: rows
    }
  end

  def num_appointments(user, appointments) do
    (appointments[user.id] || []) |> Enum.count()
  end

  def time_flown(user, transactions) do
    (transactions[user.id] || [])
    |> Enum.flat_map(& &1.line_items)
    |> Enum.reduce(0, fn line_item, acc ->
      case line_item do
        %{
          aircraft_detail: %Flight.Billing.AircraftLineItemDetail{
            hobbs_start: hobbs_start,
            hobbs_end: hobbs_end
          }
        } ->
          acc + (hobbs_end - hobbs_start)

        _ ->
          acc
      end
    end)
  end

  def time_instructed(user, transactions) do
    (transactions[user.id] || [])
    |> Enum.flat_map(& &1.line_items)
    |> Enum.reduce(0, fn line_item, acc ->
      case line_item do
        %{
          instructor_detail: %Flight.Billing.InstructorLineItemDetail{
            hour_tenths: hour_tenths
          }
        } ->
          acc + hour_tenths

        _ ->
          acc
      end
    end)
  end

  def income_generated(user, transactions) do
    (transactions[user.id] || [])
    |> Enum.reduce(0, fn transaction, acc ->
      acc + (transaction.paid_by_charge || 0)
    end)
  end

  def deducted_from_balance(user, transactions) do
    (transactions[user.id] || [])
    |> Enum.reduce(0, fn transaction, acc ->
      acc + (transaction.paid_by_balance || 0)
    end)
  end

  def credit_given(user, transactions) do
    (transactions[user.id] || [])
    |> Enum.reduce(0, fn transaction, acc ->
      case transaction do
        %{type: "credit", paid_by_charge: nil} ->
          acc + transaction.total

        _ ->
          acc
      end
    end)
  end
end
