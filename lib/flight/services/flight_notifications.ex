defmodule Flight.PushNotifications do
  alias Mondo.PushNotification

  alias Flight.Accounts.{User}

  def appointment_in_1_hour_notification(%User{} = user, appointment) do
    %PushNotification{
      title: "Appointment Reminder",
      body:
        "Hey #{user.first_name}, you have an appointment coming up at #{
          Timex.format!(appointment.start_at, "%l:%M%P", :strftime)
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
          FlightWeb.ViewHelpers.display_date(appointment.start_at, :short)
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
          FlightWeb.ViewHelpers.display_date(appointment.start_at, :short)
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
          FlightWeb.ViewHelpers.display_date(appointment.start_at, :short)
        }.",
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
      body:
        "#{approving_user.first_name} #{approving_user.last_name} charged your credit card.",
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
