defmodule Fsm.Scheduling do
  alias Flight.Scheduling.{
    Aircraft,
    Availability,
    Inspection,
    DateInspection,
    TachInspection,
    Unavailability
  }

  alias Flight.Accounts.UserAircraft
  alias Flight.Accounts.UserInstructor
  alias Flight.Scheduling
  alias Fsm.Accounts
  alias Flight.Auth.Permission

  alias Fsm.Scheduling.Appointment
  alias Fsm.Scheduling.SchedulingQueries
  alias FsmWeb.ViewHelpers
  alias FsmWeb.GraphQL.Scheduling.AppointmentView

  alias Flight.Repo
  alias Fsm.SchoolScope
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Pipe
  import Fsm.Walltime, only: [walltime_to_utc: 2, utc_to_walltime: 2]
  alias Flight.Inspections
  alias Fsm.Scheduling.Utils

  def get_appointment(appointment_id) do
    Repo.get(Appointment, appointment_id)
  end

  def get_aircraft_appointments_mechanic_user_ids(aircraft_id) do
    SchedulingQueries.get_aircraft_appointments_mechanic_user_ids_query(aircraft_id)
  |> Repo.all
  end

  def get_appointment_full_object(appointment_id) do
    SchedulingQueries.get_appointment_query(appointment_id)
    |> Ecto.Query.first
    |> Repo.one
    |> AppointmentView.map
  end

  defp delete_appointment(appointment, user, context) do
    Flight.Scheduling.delete_appointment(appointment.id, user, context)
    |> case do
      {:ok, _} ->
        {:ok, true}
      _->
        {:error, :failed}
    end
  end

  defp delete_appointment(appointment, user, context, delete_reason, delete_reason_options) do
    Flight.Scheduling.delete_appointment(appointment.id, user, context, delete_reason, delete_reason_options)
    |> case do
      {:ok, _} ->
        {:ok, true}
      _->
        {:error, :failed}
    end
  end

  def delete_appointment(%{context: %{current_user: %{school_id: school_id, id: user_id}}}=context, appointment_id) do
    appointment = get_appointment(appointment_id)
    %{roles: _roles, user: current_user} = Accounts.get_user(user_id)
    context = %{assigns: %{current_user: current_user}, school_id: school_id, params: %{"school_id" => to_string(school_id)}, request_path: "/api/appointments"}

    if Flight.Auth.Authorization.user_can?(current_user, [Permission.new(:appointment, :modify, :all)]) do
      delete_appointment(appointment, current_user, context)
    else
      if Scheduling.Appointment.is_paid?(appointment) or current_user.archived do
        {:error, "Can't delete paid appointment. Please contact administrator to re-schedule or delete the content."}
      else
        instructor_user_id = Map.get(appointment, :instructor_user_id)
        owner_user_id = Map.get(appointment, :owner_user_id)

        owner_instructor_permission =
          if owner_user_id == current_user.id do
            [
              Permission.new(
                :appointment_instructor,
                :modify,
                {:personal, owner_user_id})
            ]
          else
            []
          end

        instructor_user_id =
          if instructor_user_id == "" do
            nil
          else
            instructor_user_id
          end

        if Flight.Auth.Authorization.user_can?(current_user, [
                             Permission.new(:appointment_user, :modify, {:personal, appointment.user_id}),
                             Permission.new(
                               :appointment_instructor,
                               :modify,
                               {:personal, instructor_user_id}
                             )
                           ] ++ owner_instructor_permission) do
          delete_appointment(appointment, current_user, context)
        else
          {:error, "Can't delete appointment associated with other user."}
        end
      end
    end
  end

  def delete_appointment(%{context: %{current_user: %{school_id: school_id, id: user_id}}}=context, appointment_id, delete_reason, delete_reason_options) do
    appointment = get_appointment(appointment_id)
    %{roles: _roles, user: current_user} = Accounts.get_user(user_id)
    context = %{assigns: %{current_user: current_user}, school_id: school_id, params: %{"school_id" => to_string(school_id)}, request_path: "/api/appointments"}

    if Flight.Auth.Authorization.user_can?(current_user, [Permission.new(:appointment, :modify, :all)]) do
      delete_appointment(appointment, current_user, context)
    else
      if Scheduling.Appointment.is_paid?(appointment) or current_user.archived do
        {:error, "Can't delete paid appointment. Please contact administrator to re-schedule or delete the content."}
      else
        instructor_user_id = Map.get(appointment, :instructor_user_id)
        owner_user_id = Map.get(appointment, :owner_user_id)

        owner_instructor_permission =
          if owner_user_id == current_user.id do
            [
              Permission.new(
                :appointment_instructor,
                :modify,
                {:personal, owner_user_id})
            ]
          else
            []
          end

        instructor_user_id =
          if instructor_user_id == "" do
            nil
          else
            instructor_user_id
          end

        if Flight.Auth.Authorization.user_can?(current_user, [
                             Permission.new(:appointment_user, :modify, {:personal, appointment.user_id}),
                             Permission.new(
                               :appointment_instructor,
                               :modify,
                               {:personal, instructor_user_id}
                             )
                           ] ++ owner_instructor_permission) do
          delete_appointment(appointment, current_user, context, delete_reason, delete_reason_options)
        else
          {:error, "Can't delete appointment associated with other user."}
        end
      end
    end
  end

  def update_appointment(
      %{
        context: %{
          current_user: %{
            school_id: school_id,
            id: user_id
          }
        }
      }=context,
      appointment_data
    ) do

      appointment = get_appointment(Map.get(appointment_data, :id))

      %{ roles: _roles, user: current_user } = Accounts.get_user(user_id)

      context = %{
        assigns: %{ current_user: current_user },
        school_id: school_id,
        params: %{
          "school_id" => to_string(school_id)
        },
        request_path: "/api/appointments"
      }

    if !Flight.Auth.Authorization.user_can?(current_user, [Permission.new(:appointment, :modify, :all)])
        && Scheduling.Appointment.is_paid?(appointment)
    do
      {:error, "Can't modify paid appointment. Please contact administrator to re-schedule or update the content."}
    else
      # this is to make sure if user is already archived, don't proceed further
      # to update an appointment
      if current_user.archived do
        {:error, "Something went wrong, Please contact administrator"}
      else
        case insert_or_update_appointment(
              appointment,
              appointment_data,
              Repo.preload(context.assigns.current_user, :school),
              context
            ) do
          {:ok, appointment} ->
            appointment = get_appointment_full_object(Map.get(appointment_data, :id))
            {:ok, appointment}

          {:error, changeset} ->
            {:error, FsmWeb.ViewHelpers.human_error_messages(changeset)}
        end
      end
    end
  end

  def send_changed_notifications(appointment, modifying_user) do
    appointment = Repo.preload(appointment, [:user, :instructor_user])

    if appointment.user_id && modifying_user.id != appointment.user_id do
      Flight.PushNotifications.appointment_changed_notification(
        appointment.user,
        modifying_user,
        appointment
      )
      |> Mondo.PushService.publish()
    end

    if appointment.instructor_user && appointment.instructor_user.id != modifying_user.id do
      Flight.PushNotifications.appointment_changed_notification(
        appointment.instructor_user,
        modifying_user,
        appointment
      )
      |> Mondo.PushService.publish()
    end
  end


  def send_created_notifications(appointment, modifying_user) do
    appointment = Repo.preload(appointment, [:user, :instructor_user])

    if appointment.user_id && modifying_user.id != appointment.user_id do
      Flight.PushNotifications.appointment_created_notification(
        appointment.user,
        modifying_user,
        appointment
      )
      |> Mondo.PushService.publish()
    end

    if appointment.instructor_user && appointment.instructor_user.id != modifying_user.id do
      Flight.PushNotifications.appointment_created_notification(
        appointment.instructor_user,
        modifying_user,
        appointment
      )
      |> Mondo.PushService.publish()
    end
  end

  def upsert_appointment(
        appointment,
        attrs,
        modifying_user,
        school_context
      ) do
    school = SchoolScope.get_school(school_context.school_id)
    role = List.first(Repo.preload(modifying_user, :roles).roles)

    attrs = cond do
      Map.get(attrs, :instructor_user_id) in [nil, ""] and Map.get(role, :slug)  == "instructor" ->
        Map.put(attrs, :owner_user_id, modifying_user.id)
      Map.get(attrs, :mechanic_user_id) in [nil, ""] and Map.get(role, :slug)  == "mechanic" ->
        Map.put(attrs, :owner_user_id, modifying_user.id)
      true ->
        attrs
    end

    changeset =
      appointment
      |> SchoolScope.school_changeset(school_context)
      |> Appointment.changeset(attrs, school.timezone)

    is_create? = is_nil(appointment.id)

    if changeset.valid? do
      {temp_changeset, appointment} =
        with true <- is_create?,
             {:ok, item} <- Repo.insert(changeset) do
          {item, Map.put(appointment, :id, item.id)}
        else
          _ -> {changeset, appointment}
        end

      changeset =
        temp_changeset
        |> Appointment.changeset(%{}, school.timezone)

      {:ok, _} = apply_action(changeset, :insert)

      start_at = case get_field(changeset, :inst_start_at) do
        nil->
          get_field(changeset, :start_at)
        _->
          get_field(changeset, :inst_start_at)
      end

      end_at = case get_field(changeset, :inst_end_at) do
        nil->
          get_field(changeset, :end_at)
        _->
          get_field(changeset, :inst_end_at)
      end

      user_id = get_field(changeset, :user_id)
      instructor_user_id = get_field(changeset, :instructor_user_id)
      mechanic_user_id = get_field(changeset, :mechanic_user_id)
      aircraft_id = get_field(changeset, :aircraft_id) || get_field(changeset, :simulator_id)
      room_id = get_field(changeset, :room_id)
      _type = get_field(changeset, :type)

      excluded_appointment_ids =
        if appointment.id do
          [appointment.id]
        else
          []
        end

      # if appointment has started. do not let instructor and

      status =
         if user_id && user_id != "" do
           Availability.user_with_permission_status(
             Permission.permission_slug(:appointment_user, :modify, :personal),
             user_id,
             start_at,
             end_at,
             excluded_appointment_ids,
             [],
             school_context
           )
         else
           :available
         end

        changeset =
        case status do
          :available ->
            changeset
          :unavailable ->
            add_error(changeset, :renter_student, "is #{status}.", status: status)
          _ ->
            add_error(changeset, :renter_student, "does not exist against #{user_id} user id.", status: status)
        end

      changeset =
        if instructor_user_id do
          status =
             Availability.user_with_permission_status(
               Permission.permission_slug(:appointment_instructor, :modify, :personal),
               instructor_user_id,
               start_at,
               end_at,
               excluded_appointment_ids,
               [],
               school_context
             )

          case status do
            :available ->
              changeset
            :unavailable ->
              add_error(changeset, :instructor, "is #{status}", status: status)
            _ ->
              add_error(changeset, :instructor, "does not exist against #{instructor_user_id} instructor user id.",
                status: status
              )
          end
        else
          changeset
        end

      changeset =
        if mechanic_user_id do
          status =
              Availability.user_with_permission_status(
                Permission.permission_slug(:appointment_mechanic, :modify, :personal),
                mechanic_user_id,
                start_at,
                end_at,
                excluded_appointment_ids,
                [],
                school_context
              )

          case status do
            :available -> changeset
            :unavailable -> add_error(changeset, :mechanic, "is #{status}", status: status)
            _ ->
              add_error(changeset, :instructor, "does not exist against #{mechanic_user_id} mechanic user id.",
                status: status
              )
          end
        else
          changeset
        end

      changeset =
        if aircraft_id do
          status =
             Availability.aircraft_status(
               aircraft_id,
               start_at,
               end_at,
               excluded_appointment_ids,
               [],
               school_context
             )

          case status do
            :available ->
              changeset

            other ->
              key = if get_field(changeset, :simulator_id), do: :simulator, else: :aircraft

              add_error(changeset, key, "is #{other}", status: status)
          end
        else
          changeset
        end

      changeset =
        if room_id do
          status =
             Availability.room_status(
               room_id,
               start_at,
               end_at,
               excluded_appointment_ids,
               [],
               school_context
             )

          case status do
            :available ->
              changeset

            other ->
              add_error(changeset, :room, "is #{other}", status: status)
          end
        else
          changeset
        end

      new_aircraft_id = get_change(changeset, :aircraft_id) || get_field(changeset, :aircraft_id)

      new_simulator_id =
        get_change(changeset, :simulator_id) || get_field(changeset, :simulator_id)

      {should_delete_item, changeset} =
        if (appointment.aircraft_id != nil && appointment.aircraft_id != new_aircraft_id) or
             (appointment.simulator_id != nil && appointment.simulator_id != new_simulator_id) do
          changeset =
            changeset
            |> Appointment.changeset(
              %{
                start_tach_time: nil,
                end_tach_time: nil,
                start_hobbs_time: nil,
                end_hobbs_time: nil
              },
              school.timezone
            )

          {true, changeset}
        else
          {false, changeset}
        end

      case Repo.insert_or_update(changeset) do
        {:ok, appointment} ->
          assign_instructor_to_user = user_id not in ["", nil] && instructor_user_id not in ["", nil]
          assign_aircraft_to_user = user_id not in ["", nil] && aircraft_id not in ["", nil]
          if assign_instructor_to_user do
            Repo.insert(%UserInstructor{user_id: user_id, instructor_id: instructor_user_id}, on_conflict: :nothing)
          end
          if assign_aircraft_to_user do
            Repo.insert(%UserAircraft{user_id: user_id, aircraft_id: aircraft_id}, on_conflict: :nothing)
          end
          if should_delete_item do
            Flight.Bills.delete_appointment_aircraft(appointment.id, appointment.aircraft_id)
          end

          Mondo.Task.start(fn ->
            #            if Enum.count(changeset.changes) > 0 do
            if is_create? do
              send_created_notifications(appointment, modifying_user)
            end

            if Enum.count(changeset.changes) > 0 and !is_create? do
              send_changed_notifications(appointment, modifying_user)
            end

            #            end
          end)

          {:ok, appointment}

        other ->
          if Map.get(temp_changeset, :id) != nil && is_create? == true,
            do: Repo.delete(temp_changeset),
            else: nil

          other
      end
    else
      {:error, changeset}
    end
  end

  def create_recurring_appointment(%{context: %{current_user: %{school_id: school_id, id: user_id}}}=context, appointment_data) do
    %{roles: _roles, user: current_user} = Accounts.get_user(user_id)
    school = Fsm.SchoolScope.get_school(school_id)
    context = %{assigns: %{current_user: current_user}, school_id: school_id, params: %{"school_id" => to_string(school_id)}, request_path: "/api/appointments"}

    {:ok, data} = insert_recurring_appointments(appointment_data, Repo.preload(context.assigns.current_user, :school), context)

    errors = Map.get(data, :errors) || %{}

    human_errors = Enum.reduce(errors, %{}, fn {time, anError}, acc ->
      errors = FlightWeb.ViewHelpers.human_error_messages(anError)
      Map.put(acc, time, errors)
    end)

    {:ok, %{human_errors: human_errors}}
  end

  def insert_recurring_appointments(
    attrs,
    modifying_user,
    context
  ) do
    recurrence = Map.get(attrs, "recurrence") || Map.get(attrs, :recurrence) || %{}
    type = Map.get(recurrence, "type") || Map.get(recurrence, :type) || "" # 0 weekly, 1 monthly
    days = Map.get(recurrence, "days") || Map.get(recurrence, :days) || []
    timezone_offset = (Map.get(recurrence, "timezone_offset") || Map.get(recurrence, :timezone_offset) || 0 ) |> Utils.string_to_int
    end_date = Map.get(recurrence, "end_at") || Map.get(recurrence, :end_at)
    type = Utils.string_to_int(type)
    days = Utils.integer_list(days)
    type = if type == 0, do: :week, else: :month

    start_at = Map.get(attrs, "start_at") || Map.get(attrs, :start_at)
    end_at = Map.get(attrs, "end_at") || Map.get(attrs, :end_at)

    {pre_time, post_time} = Utils.pre_post_instructor_duration(attrs)

    Utils.calculateSchedules(type, days, end_date, start_at, end_at, timezone_offset)
    |> Enum.reduce({:ok, %{parent_id: nil, appointments: [], errors: %{}}}, fn {start_at, end_at}, acc ->
        {:ok, acc} = acc
        parent_id = Map.get(acc, :parent_id)
        pre_duration = %Timex.Duration{seconds: -pre_time, megaseconds: 0, microseconds: 0}
        inst_start_at = Timex.add(start_at, pre_duration)

        post_duration = %Timex.Duration{seconds: post_time, megaseconds: 0, microseconds: 0}
        inst_end_at = Timex.add(end_at, post_duration)

        attrs =
            attrs
            |> Map.put(:start_at, start_at)
            |> Map.put(:end_at, end_at)
            |> Map.put(:inst_start_at, inst_start_at)
            |> Map.put(:inst_end_at, inst_end_at)
            |> Map.put(:parent_id, parent_id)

        insert_or_update_appointment(%Appointment{}, attrs, modifying_user, context)
        |> case do
          {:error, changeset} ->
            errors = Map.get(acc, :errors)
            new_errors = Map.put(errors, start_at, changeset)

            {:ok, Map.put(acc, :errors, new_errors)}

          {:ok, appointment} ->
            acc =
              if parent_id == nil do
                insert_or_update_appointment(appointment, %{parent_id: appointment.id}, modifying_user, context)
                 Map.put(acc, :parent_id, appointment.id)
              else
                acc
              end
            appointments = Map.get(acc, :appointments)
            {:ok, Map.put(acc, :appointments, [appointment | appointments])}
        end
    end)
  end

  def insert_or_update_appointment(
        appointment,
        attrs,
        modifying_user,
        context
      ) do
    Repo.transaction(fn ->
      upsert_appointment(appointment, attrs, modifying_user, context)
      |> case do
        {:ok, appointment} -> appointment
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def create_appointment(%{context: %{current_user: %{school_id: school_id, id: user_id}}}=context, appointment_data) do
    %{roles: _roles, user: current_user} = Accounts.get_user(user_id)
    school = Fsm.SchoolScope.get_school(school_id)
    context = %{assigns: %{current_user: current_user}, school_id: school_id, params: %{"school_id" => to_string(school_id)}, request_path: "/api/appointments"}
    case insert_or_update_appointment(
           %Appointment{},
           appointment_data,
           Repo.preload(context.assigns.current_user, :school),
           context
         ) do
      {:ok, appointment} ->
        {:ok, appointment}

      {:error, changeset} ->
        error_messages = FsmWeb.ViewHelpers.human_error_messages(changeset)

        {:error, error_messages}
    end
  end

  ##
  # List Aircraft Appointments
  ##
  def list_aircraft_appointments(page, per_page, sort_field, sort_order, params, school_context) do
    filter = Map.put(params, :aircraft_id_is_not_null, true)

    SchedulingQueries.list_appointments_query(
      page,
      per_page,
      sort_field,
      sort_order,
      filter,
      school_context
    )
    |> Repo.all()

    #    |> FlightWeb.API.AppointmentView.preload()
  end

  ##
  # List Room Appointments
  ##
  def list_room_appointments(page, per_page, sort_field, sort_order, params, school_context) do
    filter = Map.put(params, :room_id_is_not_null, true)

    SchedulingQueries.list_appointments_query(
      page,
      per_page,
      sort_field,
      sort_order,
      filter,
      school_context
    )
    |> Repo.all()

    #    |> FlightWeb.API.AppointmentView.preload()
  end

  ##
  # List Appointments
  ##
  def list_appointments(page, per_page, sort_field, sort_order, filter, school_context) do
    SchedulingQueries.list_appointments_query(
      page,
      per_page,
      sort_field,
      sort_order,
      filter,
      school_context
    )
    |> Repo.all()

    #    |> FlightWeb.API.AppointmentView.preload()
  end

  def create_recurring_unavailability(
    attrs,
    context
  ) do
    recurrence = Map.get(attrs, "recurrence") || Map.get(attrs, :recurrence) || %{}
    type = Map.get(recurrence, "type") || Map.get(recurrence, :type) || "" # 0 weekly, 1 monthly
    days = Map.get(recurrence, "days") || Map.get(recurrence, :days) || []
    timezone_offset = (Map.get(recurrence, "timezone_offset") || Map.get(recurrence, :timezone_offset) || 0 ) |> Utils.string_to_int
    end_date = Map.get(recurrence, "end_at") || Map.get(recurrence, :end_at)
    type = Utils.string_to_int(type)
    days = Utils.integer_list(days)
    type = if type == 0, do: :week, else: :month

    start_at = Map.get(attrs, "start_at") || Map.get(attrs, :start_at)
    end_at = Map.get(attrs, "end_at") || Map.get(attrs, :end_at)

    {:ok, data} =
    Utils.calculateSchedules(type, days, end_date, start_at, end_at, timezone_offset)
    |> Enum.reduce({:ok, %{parent_id: nil, unavailabilities: [], errors: %{}}}, fn {start_at, end_at}, acc ->
        {:ok, acc} = acc
        parent_id = Map.get(acc, :parent_id)
        attrs =
            attrs
            |> Map.put(:start_at, start_at)
            |> Map.put(:end_at, end_at)
            |> Map.put(:parent_id, parent_id)

        insert_or_update_unavailability(context, %Unavailability{}, attrs)
        |> case do
          {:error, changeset} ->
            errors = Map.get(acc, :errors)
            new_errors = Map.put(errors, start_at, changeset)

            {:ok, Map.put(acc, :errors, new_errors)}

          {:ok, unavailability} ->
            acc =
              if parent_id == nil do
                insert_or_update_unavailability(context, unavailability, %{parent_id: unavailability.id})
                 Map.put(acc, :parent_id, unavailability.id)
              else
                acc
              end
            unavailabilities = Map.get(acc, :unavailabilities)
            {:ok, Map.put(acc, :unavailabilities, [unavailability | unavailabilities])}
        end
    end)

    errors = Map.get(data, :errors) || %{}

    human_errors = Enum.reduce(errors, %{}, fn {time, anError}, acc ->
      errors = FlightWeb.ViewHelpers.human_error_messages(anError)
      Map.put(acc, time, errors)
    end)

    {:ok, %{human_errors: human_errors}}
  end

  def insert_or_update_unavailability(%{context: %{current_user: %{school_id: school_id, id: user_id}}}=context, unavailability, attrs) do
    school = Fsm.SchoolScope.get_school(school_id)
    %{roles: _roles, user: current_user} = Accounts.get_user(user_id)
    school_context = %Plug.Conn{assigns: %{current_user: current_user}, params: %{"school_id" => inspect(school_id)}, request_path: "/api/"}
    changeset =
      unavailability
      |> SchoolScope.school_changeset(school)
      |> Unavailability.changeset(attrs, school.timezone)

    if changeset.valid? do
      {:ok, _} = apply_action(changeset, :insert)
      instructor_user_id = get_field(changeset, :instructor_user_id)
      aircraft_id = get_field(changeset, :aircraft_id) || get_field(changeset, :simulator_id)
      room_id = get_field(changeset, :room_id)

      excluded_unavailability_ids = if unavailability.id, do: [unavailability.id], else: []

      changeset =
        if instructor_user_id do
        start_at = get_field(changeset, :start_at) # utc time for instructor
        end_at = get_field(changeset, :end_at) # utc time for instructor
        status =
          Availability.user_with_permission_status(
            :unavailability,
            Permission.permission_slug(:appointment_instructor, :modify, :personal),
            instructor_user_id,
            start_at,
            end_at,
            [],
            excluded_unavailability_ids,
            school_context
        )
        case status do
          :available -> changeset
          other -> add_error(changeset, :instructor, "is #{other}", status: status)
        end
        else
        changeset
        end

        start_at = get_field(changeset, :start_at) #|> utc_to_walltime(school.timezone)
        end_at = get_field(changeset, :end_at) #|> utc_to_walltime(school.timezone)

        changeset =
        if aircraft_id do
          status =
            Availability.aircraft_status(:unavailability, aircraft_id, start_at, end_at, [], excluded_unavailability_ids, school_context
        )

          case status do
          :available -> changeset
          :unavailable ->
            key = if get_field(changeset, :simulator_id), do: :simulator, else: :aircraft
            add_error(changeset, key, "already have unavailability within the given time range", status: status)
          other ->
            key = if get_field(changeset, :simulator_id), do: :simulator, else: :aircraft
            add_error(changeset, key, "is #{other}", status: status)
          end
        else
          changeset
        end

        changeset =
        if room_id do
          status =
            Availability.room_status( :unavailability, room_id, start_at, end_at, excluded_unavailability_ids, [], school_context)

          case status do
            :available -> changeset
            :unavailable ->
              add_error(changeset, :room, "already have unavailability within the given time range", status: status)
            other ->
              add_error(changeset, :room, "is #{other}", status: status)
          end
        else
        changeset
        end
      Repo.insert_or_update(changeset)
    else
      {:error, changeset}
    end
  end

  def get_unavailability(nil, school_context) do
   %{}
  end

  def get_unavailability(id, school_context) do
    Unavailability
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def delete_unavailability(id, school_context) do
    unavailability = get_unavailability(id, school_context)

    if not is_nil unavailability do
      Repo.delete(unavailability)
      |> case do
       {:ok, _} ->
         {:ok, true}
       {:error, error} ->
         {:error, error}
       _->
         {:ok, false}
       end
    else
      {:error, "Unavailability not found"}
    end
  end

  def list_unavailabilities(options, school_context) do

    from_value = Map.get(options, "from")

    to_value = Map.get(options, "to")

    start_at_after_value = Map.get(options, "start_at_after")

    instructor_user_id_value = options["instructor_user_id"]
    aircraft_id_value = options["aircraft_id"]

    from(a in Unavailability)
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(start_at_after_value, &where(&1, [a], a.start_at >= ^start_at_after_value))
    |> pass_unless(
         from_value && to_value,
         &Availability.overlap_query(&1, from_value, to_value)
       )
    |> pass_unless(aircraft_id_value, &where(&1, [a], a.aircraft_id == ^aircraft_id_value))
    |> pass_unless(
         instructor_user_id_value,
         &from(a in &1, where: a.instructor_user_id == ^instructor_user_id_value)
       )
      # |> limit(200)
    |> order_by([a], desc: a.start_at)
    |> Repo.all()
  end

  def visible_air_assets(school_context) do
    SchedulingQueries.visible_air_assets_query(school_context)
    |> Repo.all()
  end

  def aircraft_query(school_context, search_term \\ "") do
    Aircraft
    |> Flight.Scheduling.Search.Aircraft.run(search_term)
    |> SchoolScope.scope_query(school_context)
  end

  def get_aircraft(id, school_context) do
    aircraft_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def ics_for_appointment(id) do
    with %{id: id, school_id: school_id} = appointment <- get_appointment_full_object(id),
      %{id: school_id} = school <- SchoolScope.get_school(school_id) do
        appointment
        |> Map.put(:school, school)
        |> Utils.url_for_appointment_ics
      else
        _ -> {:error, "Appointment with id: #{id} does not exists."}
    end
  end

  def apply_utc_timezone(changeset, key, timezone) do
    case get_change(changeset, key) do
      nil -> changeset
      change -> put_change(changeset, key, walltime_to_utc(change, timezone))
    end
  end
end
