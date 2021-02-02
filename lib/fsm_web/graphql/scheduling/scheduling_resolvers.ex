defmodule FsmWeb.GraphQL.Scheduling.SchedulingResolvers do

  alias Fsm.Scheduling
  alias Flight.Scheduling.Unavailability
  alias Flight.Accounts.School
  alias FsmWeb.GraphQL.Scheduling.AppointmentView
  alias FsmWeb.GraphQL.Log
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

  def create_appointment(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    appointment = Map.get(args, :appointment)
    Scheduling.create_appointment(context, appointment)
  end

  def create_unavailability(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    unavailability = Map.get(args, :unavailability)
    school = Repo.get(School, school_id)
    unavailability =
      if Map.get(unavailability, :aircraft_id) not in [nil, ""] or Map.get(unavailability, :simulator_id) not in [nil, ""] do
        unavailability =
          case (Map.get(unavailability, :start_at) || "") |> NaiveDateTime.from_iso8601 do
               {:ok, start_at} -> Map.put(unavailability, :start_at, walltime_to_utc(start_at, school.timezone))
               _ -> unavailability
          end

        case (Map.get(unavailability, :end_at) || "") |> NaiveDateTime.from_iso8601 do
             {:ok, end_at} -> Map.put(unavailability, :end_at, walltime_to_utc(end_at, school.timezone))
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

  def edit_unavailability(parent, %{id: id}= args, %{context: %{current_user: %{school_id: school_id}}}=context) do
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

  def delete_unavailability(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    Scheduling.delete_unavailability(args.id, context)
  end

  def edit_appointment(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    appointment = Map.get(args, :appointment)
    Scheduling.update_appointment(context, appointment)
  end

  def delete_appointment(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    Log.request(args, __ENV__.function)
    appointment_id = Map.get(args, :appointment_id)
    Scheduling.delete_appointment(context, appointment_id)
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

    sort_field = Map.get(args, :sort_field) || :start_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
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
end
  