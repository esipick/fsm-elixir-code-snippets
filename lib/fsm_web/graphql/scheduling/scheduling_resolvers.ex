defmodule FsmWeb.GraphQL.Scheduling.SchedulingResolvers do

  alias Fsm.Scheduling
  alias Flight.Scheduling.Unavailability
  alias FsmWeb.GraphQL.Scheduling.AppointmentView
  alias FsmWeb.GraphQL.Log

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
    appointment = Map.get(args, :appointment)
    Scheduling.create_appointment(context, appointment)
  end

  def create_unavailability(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    unavailability = Map.get(args, :unavailability)
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
    Scheduling.delete_unavailability(args.id, context)
  end

  def edit_appointment(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    appointment = Map.get(args, :appointment)
    Scheduling.update_appointment(context, appointment)
  end

  def delete_appointment(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    appointment_id = Map.get(args, :appointment_id)
    Scheduling.delete_appointment(context, appointment_id)
  end

  def list_aircraft_appointments(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
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
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    response =
      Scheduling.list_appointments(page, per_page, sort_field, sort_order, filter, context)
      |> AppointmentView.map

    resp = {:ok, response}
    Log.response(resp, __ENV__.function, :info)
  end

  def list_unavailabilities(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
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
  