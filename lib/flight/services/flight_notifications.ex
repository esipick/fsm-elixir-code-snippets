defmodule Flight.PushNotifications do
  import Flight.Walltime

  alias Flight.Repo
  alias Mondo.PushNotification
  alias Flight.Accounts.{User}
  alias Flight.Alerts

  def appointment_in_1_hour_notification(%User{} = user, appointment) do
    title = "Appointment Reminder"
    school_id = Map.get(appointment, :school_id) || Map.get(user, :school_id)
    receiver_id = Map.get(user, :id)
    description =
      "Hey #{user.first_name}, you have an appointment coming up at #{
        Timex.format!(
          utc_to_walltime(appointment.start_at, user.school.timezone),
          "%l:%M%P",
          :strftime
        )
      }."
    Alerts.create_notification_alert(%{title: title, description: description, receiver_id: receiver_id, code: :appointment, school_id: school_id})

    user = Repo.preload(user, :school)
    %PushNotification{
      title: "Appointment Reminder",
      body:
        "Hey #{user.first_name}, you have an appointment coming up at #{
          Timex.format!(
            utc_to_walltime(appointment.start_at, user.school.timezone),
            "%l:%M%P",
            :strftime
          )
        }.",
      sound: true,
      user_id: user.id,
      data: %{
        destination: "appointments/#{appointment.id}"
      }
    }
  end

  def appointment_created_notification(destination_user, creating_user, appointment) do
    title = "Appointment Created"
    school_id = Map.get(appointment, :school_id) || Map.get(destination_user, :school_id) || Map.get(creating_user, :school_id)
    sender_id = Map.get(creating_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description =
      "#{creating_user.first_name} #{creating_user.last_name} created an appointment for you on #{
        FlightWeb.ViewHelpers.display_walltime_date(
          appointment.start_at,
          creating_user.school.timezone,
          :short
        )
      }."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :appointment, school_id: school_id})

    %PushNotification{
      title: title,
      body: description,
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "appointments/#{appointment.id}"
      }
    }
  end

  def appointment_changed_notification(destination_user, updating_user, appointment) do
    title = "Appointment Changed"
    school_id = Map.get(appointment, :school_id) || Map.get(destination_user, :school_id) || Map.get(updating_user, :school_id)
    sender_id = Map.get(updating_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description =
      "#{updating_user.first_name} #{updating_user.last_name} updated your appointment on #{
        FlightWeb.ViewHelpers.display_walltime_date(
          appointment.start_at,
          updating_user.school.timezone,
          :short
        )
      }."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :appointment, school_id: school_id})

    %PushNotification{
      title: title,
      body: description,
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "appointments/#{appointment.id}"
      }
    }
  end

  def appointment_deleted_notification(destination_user, deleting_user, appointment) do
    title = "Appointment Deleted"
    school_id = Map.get(appointment, :school_id) || Map.get(destination_user, :school_id) || Map.get(deleting_user, :school_id)
    sender_id = Map.get(deleting_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "#{deleting_user.first_name} #{deleting_user.last_name} deleted your appointment on #{
      FlightWeb.ViewHelpers.display_walltime_date(
        appointment.start_at,
        deleting_user.school.timezone,
        :short
      )
    }."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :appointment, school_id: school_id})

    %PushNotification{
      title: title,
      body: description,
      sound: true,
      user_id: destination_user.id
    }
  end

  def squawk_created_notification(destination_user, creating_user, squawk) do
    title = "Squawk Created"
    school_id = Map.get(squawk, :school_id) || Map.get(destination_user, :school_id) || Map.get(creating_user, :school_id)
    sender_id = Map.get(creating_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "A squawk for plane "<>squawk.aircraft.make<>" "<>squawk.aircraft.model<>" - "<>squawk.aircraft.tail_number<>" has been created by "<>creating_user.first_name<>" "<>creating_user.last_name<>"."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :squawk, school_id: school_id})

    %PushNotification{
      title: title,
      body: description,
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "aircrafts/#{squawk.aircraft_id}"
      }
    }
  end

  def squawk_updated_notification(destination_user, updating_user, squawk) do
    title = "Squawk Updated"
    school_id = Map.get(squawk, :school_id) || Map.get(destination_user, :school_id) || Map.get(updating_user, :school_id)
    sender_id = Map.get(updating_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "A squawk for plane "<>squawk.aircraft.make<>" "<>squawk.aircraft.model<>" - "<>squawk.aircraft.tail_number<>" has been updated by "<>updating_user.first_name<>" "<>updating_user.last_name<>"."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :squawk, school_id: school_id})

    %PushNotification{
      title: title,
      body: description,
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "aircrafts/#{squawk.aircraft_id}"
      }
    }
  end

  def squawk_resolved_notification(destination_user, resolving_user, squawk) do
    title = "Squawk Resolved"
    school_id = Map.get(squawk, :school_id) || Map.get(destination_user, :school_id) || Map.get(resolving_user, :school_id)
    sender_id = Map.get(resolving_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "A squawk for plane "<>squawk.aircraft.make<>" "<>squawk.aircraft.model<>" - "<>squawk.aircraft.tail_number<>" has been resolved by "<>resolving_user.first_name<>" "<>resolving_user.last_name<>"."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :squawk, school_id: school_id})

    %PushNotification{
      title: title,
      body: description,
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "aircrafts/#{squawk.aircraft_id}"
      }
    }
  end

  def squawk_deleted_notification(destination_user, deleting_user, squawk) do
    title = "Squawk Deleted"
    school_id = Map.get(squawk, :school_id) || Map.get(destination_user, :school_id) || Map.get(deleting_user, :school_id)
    sender_id = Map.get(deleting_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "A squawk for plane "<>squawk.aircraft.make<>" "<>squawk.aircraft.model<>" - "<>squawk.aircraft.tail_number<>" has been deleted by "<>deleting_user.first_name<>" "<>deleting_user.last_name<>"."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :squawk, school_id: school_id})


    %PushNotification{
      title: "Squawk Deleted",
      body: description,
      sound: true,
      user_id: destination_user.id
    }
  end

  def payment_request_notification(destination_user, requesting_user, transaction) do
    title = "Payment Request"
    school_id = Map.get(transaction, :school_id) || Map.get(destination_user, :school_id) || Map.get(requesting_user, :school_id)
    sender_id = Map.get(requesting_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "#{requesting_user.first_name} #{requesting_user.last_name} sent you a payment request to approve against transaction id #{transaction.id}."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :payment, school_id: school_id})

    %PushNotification{
      title: title,
      body:
        "#{requesting_user.first_name} #{requesting_user.last_name} sent you a payment request to approve.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "transactions/#{transaction.id}"
      }
    }
  end

  def payment_approved_notification(destination_user, approving_user, transaction) do
    title = "Payment Approved"
    school_id = Map.get(transaction, :school_id) || Map.get(destination_user, :school_id) || Map.get(approving_user, :school_id)
    sender_id = Map.get(approving_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "#{approving_user.first_name} #{approving_user.last_name} approved your payment request against transaction id #{transaction.id}."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :payment, school_id: school_id})

    %PushNotification{
      title: title,
      body:
        "#{approving_user.first_name} #{approving_user.last_name} approved your payment request.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "transactions/#{transaction.id}"
      }
    }
  end

  def credit_card_charged_notification(destination_user, approving_user, transaction) do
    title = "Payment Approved"
    school_id = Map.get(transaction, :school_id) || Map.get(destination_user, :school_id) || Map.get(approving_user, :school_id)
    sender_id = Map.get(approving_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "#{approving_user.first_name} #{approving_user.last_name} charged your credit card against transaction id #{transaction.id}."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :payment, school_id: school_id})

    %PushNotification{
      title: "Payment Approved",
      body: "#{approving_user.first_name} #{approving_user.last_name} charged your credit card.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "transactions/#{transaction.id}"
      }
    }
  end

  def balance_deducted_notification(
        destination_user,
        deducting_user,
        transaction
      ) do
    title = "Payment"
    school_id = Map.get(transaction, :school_id) || Map.get(destination_user, :school_id) || Map.get(deducting_user, :school_id)
    sender_id = Map.get(deducting_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "#{deducting_user.first_name} #{deducting_user.last_name} deducted funds from your balance against transaction id #{transaction.id}."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :payment, school_id: school_id})

    %PushNotification{
      title: title,
      body:
        "#{deducting_user.first_name} #{deducting_user.last_name} deducted funds from your balance.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "transactions/#{transaction.id}"
      }
    }
  end

  def cash_payment_received_notification(
        destination_user,
        deducting_user,
        transaction
      ) do
    title = "Payment"
    school_id = Map.get(transaction, :school_id) || Map.get(destination_user, :school_id) || Map.get(deducting_user, :school_id)
    sender_id = Map.get(deducting_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "#{deducting_user.first_name} #{deducting_user.last_name} accepted a cash or gift card payment against transaction id #{transaction.id}."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :payment, school_id: school_id})

    %PushNotification{
      title: title,
      body:
        "#{deducting_user.first_name} #{deducting_user.last_name} accepted a cash or gift card payment.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "transactions/#{transaction.id}"
      }
    }
  end

  def funds_added_notification(
        destination_user,
        deducting_user,
        transaction
      ) do
    title = "New Funds"
    school_id = Map.get(transaction, :school_id) || Map.get(destination_user, :school_id) || Map.get(deducting_user, :school_id)
    sender_id = Map.get(deducting_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "#{deducting_user.first_name} #{deducting_user.last_name} added funds to your balance against transaction id #{transaction.id}."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :payment, school_id: school_id})

    %PushNotification{
      title: title,
      body:
        "#{deducting_user.first_name} #{deducting_user.last_name} added funds to your balance.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "transactions/#{transaction.id}"
      }
    }
  end

  def funds_removed_notification(
        destination_user,
        deducting_user,
        transaction
      ) do
    title = "Funds Removed"
    school_id = Map.get(transaction, :school_id) || Map.get(destination_user, :school_id) || Map.get(deducting_user, :school_id)
    sender_id = Map.get(deducting_user, :id)
    receiver_id = Map.get(destination_user, :id)
    description = "#{deducting_user.first_name} #{deducting_user.last_name} removed funds from your balance against transaction id #{transaction.id}."
    Alerts.create_notification_alert(%{title: title, description: description, sender_id: sender_id, receiver_id: receiver_id, code: :payment, school_id: school_id})

    %PushNotification{
      title: title,
      body:
        "#{deducting_user.first_name} #{deducting_user.last_name} removed funds from your balance.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "transactions/#{transaction.id}"
      }
    }
  end

  def outstanding_payment_request_notification(destination_user_id) do
    title = "Outstanding Payments"
    school_id = Flight.Accounts.dangerous_get_user(destination_user_id) |> Map.get(:school_id)
    receiver_id = destination_user_id
    description = "You have one or more outstanding payment requests."
    Alerts.create_notification_alert(%{title: title, description: description, receiver_id: receiver_id, code: :payment, school_id: school_id})

    %PushNotification{
      title: title,
      body: "You have one or more outstanding payment requests.",
      sound: true,
      user_id: destination_user_id,
      data: %{
        destination: "transactions"
      }
    }
  end

  def test_notification(user_id) do
    %Mondo.PushNotification{
      title: "Hello World",
      body: "This is a test notification.",
      sound: true,
      user_id: user_id
    }
  end
end
