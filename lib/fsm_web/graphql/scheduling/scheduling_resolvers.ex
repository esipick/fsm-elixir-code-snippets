defmodule FsmWeb.GraphQL.Scheduling.SchedulingResolvers do
  import Flight.Auth.Authorization

  alias Fsm.Scheduling
  alias Flight.Scheduling.Unavailability
  alias Flight.Accounts.School
  alias FsmWeb.GraphQL.Scheduling.AppointmentView
  alias FsmWeb.GraphQL.Log
  alias Flight.Auth.Permission
  alias Flight.Repo

  import Fsm.Walltime, only: [walltime_to_utc: 2, utc_to_walltime: 2]

#  def login(_parent, %{email: email, password: password} = params, resolution) do
#    resp = Accounts.api_login(%{"email" => email, "password"=> password} )
#
#    Log.response(resp, __ENV__.function, :info)
#  end
#
#  def get_current_user(parent, _args, %{context: %{current_user: %{id: id}}}=context) do
#    user =
#      Accounts.get_user(id)
#      |> UserView.map
#
#    resp = {:ok, user}
#    Log.response(resp, __ENV__.function)
#  end
#
#  def get_user(parent, args, %{context: %{current_user: %{id: id}}}=context) do
#    user =
#      Accounts.get_user(args.id)
#      |> UserView.map
#
#    resp = {:ok, user}
#    Log.response(resp, __ENV__.function)
#  end

  def create_recurring_unavailability(parent, %{
    unavailability: %{
      recurrence: recurrence
    }
  } = args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)

    type = if Map.get(recurrence, :type) == :weekly, do: 0, else: 1
    recurrence = Map.put(recurrence, :type, type)
    unavailability =
      args
      |> Map.get(:unavailability)
      |> Map.put(:recurrence, recurrence)

    Scheduling.create_recurring_unavailability(unavailability, context)
  end
  def create_recurring_unavailability(_,_,_), do: {:error, "Invalid API Arguments."}

  def create_recurring_appointment(parent, %{
    appointment: %{
      recurrence: recurrence
      }
      } = args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)

    type = if Map.get(recurrence, :type) == :weekly, do: 0, else: 1
    recurrence = Map.put(recurrence, :type, type)
    appointment =
      args
      |> Map.get(:appointment)
      |> Map.put(:recurrence, recurrence)

    Scheduling.create_recurring_appointment(context, appointment)
  end

  def create_appointment(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    appointment = Map.get(args, :appointment)
    Scheduling.create_appointment(context, appointment)
  end

  def create_unavailability(parent, args, %{context: %{current_user: %{id: modifier_user_id, school_id: school_id}}}=context) do
    with %{resp_body: nil} <- authorize_modify(args, context) do
    Log.request(args, __ENV__.function)
    unavailability = Map.get(args, :unavailability)
    school = Repo.get(School, school_id)
    unavailability =
      if Map.get(unavailability, :aircraft_id) not in [nil, ""] or Map.get(unavailability, :simulator_id) not in [nil, ""] do
        unavailability =
          case (Map.get(unavailability, :start_at) || "") |> NaiveDateTime.from_iso8601 do
               {:ok, start_at} -> Map.put(unavailability, :start_at, start_at)
               _ -> unavailability
          end

        case (Map.get(unavailability, :end_at) || "") |> NaiveDateTime.from_iso8601 do
             {:ok, end_at} -> Map.put(unavailability, :end_at, end_at)
             _ -> unavailability
        end
      else
        unavailability
      end

    Scheduling.insert_or_update_unavailability(context, %Unavailability{}, unavailability)
    |> case do
      {:error, changeset} ->
        error_messages = FsmWeb.ViewHelpers.human_error_messages(changeset)
        {:error, error_messages}
      changeset ->
        changeset
    end
  end
  end

  defp authorize_modify(args, %{context: %{current_user: %{id: modifier_user_id}}}=context) do
    %{roles: _roles, user: current_user} = Fsm.Accounts.get_user(modifier_user_id)
    id = Map.get(args, :id)
    unavailability =
      Map.get(args, :id)
      |> Scheduling.get_unavailability(context)
    conn = %Plug.Conn{assigns: %{current_user: current_user, unavailability: unavailability}}
    instructor_user_id_from_unavailability =
      case conn.assigns do
        %{unavailability: %{instructor_user_id: id}} -> id
        _ -> nil
      end

    instructor_user_id =
      (Map.get(args, :unavailability)) |> Optional.map(& &1[:instructor_user_id]) ||
        instructor_user_id_from_unavailability

    cond do
      parse_to_boolean(instructor_user_id) ->
        if user_can?(conn.assigns.current_user, [
          Permission.new(:unavailability_instructor, :modify, {:personal, instructor_user_id}),
          Permission.new(:unavailability_instructor, :modify, :all),
          Permission.new(:unavailability, :modify, :all)
        ]) do
          conn
        else
          {:error, "unauthorized"}
        end

      user_can?(conn.assigns.current_user, [
        Permission.new(:unavailability_aircraft, :modify, :all),
        Permission.new(:unavailability_instructor, :modify, :all),
        Permission.new(:unavailability, :modify, :all)
      ]) ->
        conn

      true ->
        {:error, "unauthorized"}
    end
  end

  defp parse_to_boolean(instructor_user_id) do
    case instructor_user_id do
      nil -> nil
      "" -> nil
      _ -> true
    end
  end

  def edit_unavailability(parent, %{id: id}= args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    with %{resp_body: nil} <- authorize_modify(args, context) do
      Log.request(args, __ENV__.function)
      unavailability_attrs = Map.get(args, :unavailability)
      unavailability = Flight.Repo.get(Unavailability, id)

      Scheduling.insert_or_update_unavailability(context, unavailability, unavailability_attrs)
      |> case do
        {:error, changeset} ->
          error_messages = FsmWeb.ViewHelpers.human_error_messages(changeset)
          {:error, error_messages}
        changeset ->
          changeset
      end
    end
  end

  def delete_unavailability(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    with %{resp_body: nil} <- authorize_modify(args, context) do
      Log.request(args, __ENV__.function)
      Scheduling.delete_unavailability(args.id, context)
    end
  end

  def edit_appointment(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    appointment = Map.get(args, :appointment)
    Scheduling.update_appointment(context, appointment)
  end

  def delete_appointment(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    appointment_id = Map.get(args, :appointment_id)
    delete_reason = Map.get(args, :delete_reason)
    delete_reason_options = Map.get(args, :delete_reason_options)
    Scheduling.delete_appointment(context, appointment_id, delete_reason, delete_reason_options)
  end

  def delete_recurring_appointment(parent, %{id: id, parent_id: parent_id} = args, %{context: %{current_user: %{school_id: school_id}=school_context}}=context) do
    appt = Flight.Scheduling.get_appointment(id, school_context)
    options = %{
      start_date: appt.start_at,
      parent_id: parent_id
    }

    appointments = Flight.Scheduling.get_recurring_appointments_for_deletion(options, school_context)

    response = Enum.map(appointments, fn appointment ->

                  with {:ok, true } <- Scheduling.delete_appointment(context, appointment.id) do
                    %{
                      appointment: appointment,
                      delete: true,
                      reason: ""
                    }
                  else
                    {:error, reason }  ->
                      %{
                        appointment: appointment,
                        delete: false,
                        reason: reason
                      }
                  end
               end)

    resp = {:ok, response}
  end

  def delete_recurring_unavailability(parent,%{id: id, parent_id: parent_id} = args, %{context: %{current_user: %{school_id: school_id}=school_context}}=context) do
    Log.request(args, __ENV__.function)
    with %{resp_body: nil} <- authorize_modify(args, context) do
      unavailability = Scheduling.get_unavailability(id, context)
      options = %{
        start_date: unavailability.start_at,
        parent_id: parent_id
      }
      with {records_deleted, nil} <- Flight.Scheduling.delete_recurring_unavailability(options, school_context) do
        response = %{
          message: "Unavailabilities Deleted Successfully",
          error: false
        }
        {:ok, response}
      else
        response = {records_deleted, :error } ->
          %{
            message: :error,
            error: true
          }
        {:ok, response}
      end
    end
  end

  def list_aircraft_appointments(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    response =
      Scheduling.list_aircraft_appointments(page, per_page, sort_field, sort_order, filter, context)
      |> AppointmentView.map

    resp = {:ok, response}
    Log.response(resp, __ENV__.function, :info)
  end

  def list_room_appointments(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    response =
      Scheduling.list_room_appointments(page, per_page, sort_field, sort_order, filter, context)
      |> AppointmentView.map

    {:ok, response}
  end

  def list_appointments(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)
    filter = Map.get(args, :filter) || %{}

    sort_field = Map.get(args, :sort_field) || :start_at
    sort_order = Map.get(args, :sort_order) || (Map.get(filter, :past) && :desc || :asc)
    response =
      Scheduling.list_appointments(page, per_page, sort_field, sort_order, filter, context)
      |> AppointmentView.map

    resp = {:ok, response}
    Log.response(resp, __ENV__.function, :info)
  end

  def list_unavailabilities(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
#    page = Map.get(args, :page)
#    per_page = Map.get(args, :per_page)
#
#    sort_field = Map.get(args, :sort_field) || :inserted_at
#    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    params = %{
                "from" => Map.get(filter, :from),
                "to" => Map.get(filter, :to),
                "start_at_after" => Map.get(filter, :start_at_after),
                "instructor_user_id" => Map.get(filter, :instructor_user_id),
                "aircraft_id" => Map.get(filter, :aircraft_id)
            }

    response =
      Scheduling.list_unavailabilities(params, context)
#      |> FlightWeb.API.UnavailabilityView.preload()

    resp = {:ok, response}
    Log.response(resp, __ENV__.function, :info)
  end

  def appointment_ics_url(parent, %{appointment_id: appointment_id} = args, context) do
    Log.request(args, __ENV__.function)

    Scheduling.ics_for_appointment(appointment_id)
  end
end
