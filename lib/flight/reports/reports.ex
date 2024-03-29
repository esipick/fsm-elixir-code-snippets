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

  @format_str "{0M}-{0D}-{YYYY}"

  def parse_date(date) do
    date
    |> Timex.parse!(@format_str)
    |> Timex.to_naive_datetime()
  end

  def format_date(date) do
    date
    |> Timex.format!(@format_str)
  end

  def report(report_type, from, to, school_context) when is_binary(from) and is_binary(to) do
    start_at = parse_date(from)

    end_at =
      to
      |> parse_date()
      |> Timex.shift(days: 1)

    case report_type do
      "students" -> student_report(start_at, end_at, school_context)
      "instructors" -> instructor_report(start_at, end_at, school_context)
      "renters" -> renter_report(start_at, end_at, school_context)
      "aircrafts" -> aircraft_report(start_at, end_at, false, school_context)
      "simulators" -> aircraft_report(start_at, end_at, true, school_context)
    end
  end

  def student_report(start_at, end_at, school_context) do
    users = get_users(Role.student(), school_context)

    user_ids = Enum.map(users, & &1.id)

    appointments = get_renter_appointments(user_ids, start_at, end_at, school_context)

    transactions = get_renter_transactions(user_ids, start_at, end_at, school_context)

    %Flight.ReportTable{
      headers: [
        "Name",
        "# of Appts",
        "Time Flown",
        "Time Instructed",
        "Income Generated",
        "Credit Given",
        "Deducted from Balance"
      ],
      rows:
        users
        |> Enum.filter(
          &(num_appointments(&1, appointments) > 0 || num_transactions(&1, transactions) > 0)
        )
        |> Enum.map(fn user ->
          [
            {user.id, "#{user.first_name} #{user.last_name}", user.archived},
            num_appointments(user, appointments),
            time_flown(user, transactions),
            time_instructed(user, transactions),
            income_generated(user, transactions),
            credit_given(user, transactions),
            deducted_from_balance(user, transactions)
          ]
        end)
        |> add_total_row
    }
  end

  def renter_report(start_at, end_at, school_context) do
    users = get_users(Role.renter(), school_context)

    user_ids = Enum.map(users, & &1.id)

    transactions = get_renter_transactions(user_ids, start_at, end_at, school_context)

    %Flight.ReportTable{
      headers: [
        "Name",
        "# of Appts",
        "Time Flown",
        "Income Generated",
        "Credit Given",
        "Deducted from Balance"
      ],
      rows:
        Enum.map(users, fn user ->
          [
            {user.id, "#{user.first_name} #{user.last_name}", user.archived},
            num_transactions(user, transactions),
            time_flown(user, transactions),
            income_generated(user, transactions),
            credit_given(user, transactions),
            deducted_from_balance(user, transactions)
          ]
        end)
        |> add_total_row
    }
  end

  def instructor_report(start_at, end_at, school_context) do
    users = get_users(Role.instructor(), school_context)

    user_ids = Enum.map(users, & &1.id)

    appointments = get_instructor_appointments(user_ids, start_at, end_at, school_context)

    transactions = get_instructor_transactions(user_ids, start_at, end_at, school_context)

    %Flight.ReportTable{
      headers: [
        "Name",
        "# of Appts",
        "# of Flights",
        "Flight Hours",
        "Instruction Hours",
        "Money Billed"
      ],
      rows:
        Enum.map(users, fn user ->
          [
            {user.id, "#{user.first_name} #{user.last_name}", user.archived},
            num_appointments(user, appointments),
            num_flights(user, transactions),
            time_flown(user, transactions),
            time_instructed(user, transactions),
            amount_instructor_billed(user, transactions)
          ]
        end)
        |> add_total_row
    }
  end

  def aircraft_report(start_at, end_at, simulator, school_context) do
    aircrafts = if simulator, do: Flight.Accounts.get_simulators_only(school_context), else: Flight.Accounts.get_aircrafts_only(school_context)
    aircraft_ids = Enum.map(aircrafts, & &1.id)

    # appointments = get_aircraft_appointments(aircraft_ids, start_at, end_at, school_context)

    transactions = get_aircraft_transactions(aircraft_ids, start_at, end_at, school_context)

    %Flight.ReportTable{
      headers: [
        "Name",
        "# of Flights",
        "Time Flown",
        "Money Billed",
        "Total Incl. Tax"
      ],
      rows:
        Enum.map(aircrafts, fn aircraft ->
          [
            {aircraft.id, FlightWeb.ViewHelpers.aircraft_display_name(aircraft, :short),
             aircraft.archived},
            num_transactions(aircraft, transactions),
            aircraft_time_flown(aircraft, transactions),
            amount_aircraft_billed(aircraft, transactions),
            amount_aircraft_incl_tax(aircraft, transactions)
          ]
        end)
        |> add_total_row
    }
  end

  def get_users(role, school_context) do
    User
    |> SchoolScope.scope_query(school_context)
    |> join(:inner, [u], r in UserRole, on: r.user_id == u.id)
    |> where([u, r], r.role_id == ^role.id)
    |> Repo.all()
  end

  def get_renter_appointments(user_ids, start_at, end_at, school_context) do
    from(a in Appointment, where: a.archived == false)
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.user_id in ^user_ids)
    |> where([a], a.start_at >= ^start_at and a.start_at < ^end_at)
    |> Repo.all()
    |> Enum.group_by(& &1.user_id)
  end

  def get_aircraft_appointments(aircraft_ids, start_at, end_at, school_context) do
    from(a in Appointment, where: a.archived == false)
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.aircraft_id in ^aircraft_ids)
    |> where([a], a.start_at >= ^start_at and a.start_at < ^end_at)
    |> Repo.all()
    |> Enum.group_by(& &1.aircraft_id)
  end

  def get_instructor_appointments(user_ids, start_at, end_at, school_context) do
    from(a in Appointment, where: a.archived == false)
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.instructor_user_id in ^user_ids)
    |> where([a], a.start_at >= ^start_at and a.start_at < ^end_at)
    |> Repo.all()
    |> Enum.group_by(& &1.instructor_user_id)
  end

  def get_renter_transactions(user_ids, start_at, end_at, school_context) do
    Transaction
    |> SchoolScope.scope_query(school_context)
    |> where([t], t.user_id in ^user_ids)
    |> where([t], t.state == "completed")
    |> where([t], t.completed_at >= ^start_at and t.completed_at < ^end_at)
    |> Repo.all()
    |> Repo.preload(line_items: [:aircraft_detail, :instructor_detail])
    |> Enum.group_by(& &1.user_id)
  end

  def get_instructor_transactions(user_ids, start_at, end_at, school_context) do
    Transaction
    |> SchoolScope.scope_query(school_context)
    |> join(:inner, [t], li in assoc(t, :line_items))
    |> join(:inner, [t, li], id in assoc(li, :instructor_detail))
    |> where([t, li, id], id.instructor_user_id in ^user_ids)
    |> where([t], t.state == "completed")
    |> where([t], t.completed_at >= ^start_at and t.completed_at < ^end_at)
    |> Repo.all()
    |> Repo.preload(line_items: [:aircraft_detail, :instructor_detail])
    |> Enum.group_by(fn transaction ->
      Enum.find(transaction.line_items, & &1.instructor_detail).instructor_detail.instructor_user_id
    end)
  end

  def get_aircraft_transactions(aircraft_ids, start_at, end_at, school_context) do
    Transaction
    |> SchoolScope.scope_query(school_context)
    |> join(:inner, [t], li in assoc(t, :line_items))
    |> join(:inner, [t, li], ad in assoc(li, :aircraft_detail))
    |> where([t, li, ad], ad.aircraft_id in ^aircraft_ids)
    |> where([t], t.state == "completed")
    |> where([t], t.completed_at >= ^start_at and t.completed_at < ^end_at)
    |> Repo.all()
    |> Repo.preload(line_items: [:aircraft_detail, :instructor_detail])
    |> Enum.group_by(fn transaction ->
        Enum.find(transaction.line_items, & &1.aircraft_detail).aircraft_detail.aircraft_id
    end)
  end

  def num_appointments(user, appointments) do
    (appointments[user.id] || []) |> Enum.count()
  end

  def num_transactions(user, transactions) do
    (transactions[user.id] || []) |> Enum.count()
  end

  def num_flights(user, transactions) do
    (transactions[user.id] || [])
    |> Enum.flat_map(& &1.line_items)
    |> Enum.reduce(0, fn line_item, acc ->
      case line_item do
        %{
          aircraft_detail: %Flight.Billing.AircraftLineItemDetail{
            hobbs_start: _hobbs_start,
            hobbs_end: _hobbs_end
          }
        } ->
          acc + 1

        _ ->
          acc
      end
    end)
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

  def aircraft_time_flown(aircraft, transactions) do
    (transactions[aircraft.id] || [])
    |> Enum.flat_map(& &1.line_items)
    |> Enum.reduce(0, fn line_item, acc ->
      case line_item do
        %{
          aircraft_id: id,
          aircraft_detail: %Flight.Billing.AircraftLineItemDetail{
            hobbs_start: hobbs_start,
            hobbs_end: hobbs_end
          }
        } ->

          if aircraft.id == id do
            acc + (hobbs_end - hobbs_start)
          else
            acc
          end

        _ ->
          acc
      end
    end)
  end

  def amount_aircraft_billed(aircraft, transactions) do
    (transactions[aircraft.id] || [])
    |> Enum.flat_map(& &1.line_items)
    |> Enum.reduce(0, fn line_item, acc ->
      case line_item do
        %{
          aircraft_id: id,
          aircraft_detail: %Flight.Billing.AircraftLineItemDetail{},
          amount: amount
        } ->
          if id == aircraft.id do
            acc + amount
          else
            acc
          end

        _ ->
          acc
      end
    end)
  end

  def amount_aircraft_incl_tax(aircraft, transactions) do
    (transactions[aircraft.id] || [])
    |> Enum.flat_map(& &1.line_items)
    |> Enum.reduce(0, fn line_item, acc ->
      case line_item do
        %{
          aircraft_id: id,
          aircraft_detail: %Flight.Billing.AircraftLineItemDetail{},
          amount: amount,
          total_tax: total_tax
        } ->
          if id == aircraft.id do
            acc + amount + total_tax
          else
            acc
          end

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

  def amount_instructor_billed(user, transactions) do
    (transactions[user.id] || [])
    |> Enum.flat_map(& &1.line_items)
    |> Enum.reduce(0, fn line_item, acc ->
      case line_item do
        %{
          instructor_detail: %Flight.Billing.InstructorLineItemDetail{},
          amount: amount
        } ->
          acc + amount

        _ ->
          acc
      end
    end)
  end

  def income_generated(user, transactions) do
    (transactions[user.id] || [])
    |> Enum.reduce(0, fn transaction, acc ->
      acc +
        (transaction.paid_by_cash ||
           transaction.paid_by_charge ||
           transaction.paid_by_balance ||
           transaction.paid_by_check ||
           transaction.paid_by_venmo || 0)
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

  defp add_total_row([]), do: []
  defp add_total_row(items) do
    [_name | zipped] = Enum.zip(items)

    zipped
    |> Enum.map(&(&1 |> Tuple.to_list |> Enum.sum))
    |> case do
      [] -> items
      total_row -> 
        total_row = [{nil, "All", false} | total_row]
        [total_row | items]
    end
  end
end
