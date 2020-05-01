defmodule Flight.PushNotificationsTest do
  use Flight.DataCase

  alias Flight.PushNotifications

  test "appointment_in_1_hour_notification" do
    user = user_fixture()

    appointment =
      appointment_fixture(%{start_at: ~N[2038-03-03 10:00:00], end_at: ~N[2038-03-03 11:00:00]})

    notification =
      PushNotifications.appointment_in_1_hour_notification(
        user,
        appointment
      )

    assert notification.body =~ " 10:00am"
  end

  test "appointment_created_notification" do
    PushNotifications.appointment_created_notification(
      user_fixture(),
      user_fixture(),
      appointment_fixture()
    )
  end

  test "appointment_changed_notification" do
    PushNotifications.appointment_changed_notification(
      user_fixture(),
      user_fixture(),
      appointment_fixture()
    )
  end

  test "appointment_deleted_notification" do
    PushNotifications.appointment_deleted_notification(
      user_fixture(),
      user_fixture(),
      appointment_fixture()
    )
  end

  test "payment_request_notification" do
    PushNotifications.payment_request_notification(
      user_fixture(),
      user_fixture(),
      transaction_fixture()
    )
  end

  test "payment_approved_notification" do
    PushNotifications.payment_approved_notification(
      user_fixture(),
      user_fixture(),
      transaction_fixture()
    )
  end

  test "balance_deducted_notification" do
    PushNotifications.balance_deducted_notification(
      user_fixture(),
      user_fixture(),
      transaction_fixture()
    )
  end

  test "funds_added_notification" do
    PushNotifications.funds_added_notification(
      user_fixture(),
      user_fixture(),
      transaction_fixture()
    )
  end

  test "outstanding_payment_request_notification" do
    PushNotifications.outstanding_payment_request_notification(user_fixture())
  end
end
