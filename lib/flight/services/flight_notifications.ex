defmodule Flight.PushNotifications do
  import Flight.Walltime

  alias Flight.Repo
  alias Mondo.PushNotification
  alias Flight.Accounts.{User}

  def appointment_in_1_hour_notification(%User{} = user, appointment) do
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
    %PushNotification{
      title: "Appointment Created",
      body:
        "#{creating_user.first_name} #{creating_user.last_name} created an appointment for you on #{
          FlightWeb.ViewHelpers.display_walltime_date(
            appointment.start_at,
            creating_user.school.timezone,
            :short
          )
        }.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "appointments/#{appointment.id}"
      }
    }
  end

  def appointment_changed_notification(destination_user, updating_user, appointment) do
    %PushNotification{
      title: "Appointment Changed",
      body:
        "#{updating_user.first_name} #{updating_user.last_name} updated your appointment on #{
          FlightWeb.ViewHelpers.display_walltime_date(
            appointment.start_at,
            updating_user.school.timezone,
            :short
          )
        }.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "appointments/#{appointment.id}"
      }
    }
  end

  def appointment_deleted_notification(destination_user, deleting_user, appointment) do
    %PushNotification{
      title: "Appointment Deleted",
      body:
        "#{deleting_user.first_name} #{deleting_user.last_name} deleted your appointment on #{
          FlightWeb.ViewHelpers.display_walltime_date(
            appointment.start_at,
            deleting_user.school.timezone,
            :short
          )
        }.",
      sound: true,
      user_id: destination_user.id
    }
  end

  def squawk_created_notification(destination_user, creating_user, squawk) do
    %PushNotification{
      title: "Squawk Created",
      body:
        "A new squawk for plane #{squawk.aircraft.make} #{squawk.aircraft.model} - #{squawk.aircraft.tail_number} has been created by #{creating_user.first_name} #{creating_user.last_name}.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "aircrafts/#{squawk.aircraft_id}"
      }
    }
  end

  def squawk_updated_notification(destination_user, updating_user, squawk) do
    %PushNotification{
      title: "Squawk Updated",
      body:
      "A squawk for plane #{squawk.aircraft.make} #{squawk.aircraft.model} - #{squawk.aircraft.tail_number} has been updated by #{updating_user.first_name} #{updating_user.last_name}.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "aircrafts/#{squawk.aircraft_id}"
      }
    }
  end

  def squawk_resolved_notification(destination_user, resolving_user, squawk) do
    %PushNotification{
      title: "Squawk Resolved",
      body:
      "A squawk for plane #{squawk.aircraft.make} #{squawk.aircraft.model} - #{squawk.aircraft.tail_number} has been resolved by #{resolving_user.first_name} #{resolving_user.last_name}.",
      sound: true,
      user_id: destination_user.id,
      data: %{
        destination: "aircrafts/#{squawk.aircraft_id}"
      }
    }
  end

  def squawk_deleted_notification(destination_user, deleting_user, squawk) do
    %PushNotification{
      title: "Squawk Deleted",
      body:
      "A squawk for plane #{squawk.aircraft.make} #{squawk.aircraft.model} - #{squawk.aircraft.tail_number} has been deleted by #{deleting_user.first_name} #{deleting_user.last_name}.",
      sound: true,
      user_id: destination_user.id
    }
  end

  def payment_request_notification(destination_user, requesting_user, transaction) do
    %PushNotification{
      title: "Payment Request",
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
    %PushNotification{
      title: "Payment Approved",
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
    %PushNotification{
      title: "Payment",
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
    %PushNotification{
      title: "Payment",
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
    %PushNotification{
      title: "New Funds",
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
    %PushNotification{
      title: "Funds Removed",
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
    %PushNotification{
      title: "Outstanding Payments",
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
