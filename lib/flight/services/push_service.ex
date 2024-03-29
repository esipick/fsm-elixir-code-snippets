defmodule Mondo.PushService do
  use GenServer

  require Logger
  require Ecto.Query
  import Ecto.Query, only: [from: 2]

  @api_client Application.get_env(:flight, :push_service_client)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def create_ios_endpoint(token) do
    result =
      @api_client.aws_create_platform_endpoint(
        Application.get_env(:flight, :aws_apns_application_arn),
        token
      )

    case result do
      {:ok, response} ->
        {:ok, response.body.endpoint_arn}

      error ->
        error
    end
  end

  def create_android_endpoint(token) do
    result =
      @api_client.aws_create_platform_endpoint(
        Application.get_env(:flight, :aws_gcm_application_arn),
        token
      )

    case result do
      {:ok, response} ->
        {:ok, response.body.endpoint_arn}

      error ->
        error
    end
  end

  # TODO: This could be more exhaustively tested by taking an api_client parameter, defaulting to @api_client perhaps.
  # The passed-in client could return different error codes to makes sure the error paths are taken correctly.
  def publish(push_notification) do
    payload = sns_payload_for_push_notification(push_notification)

    for token <- tokens_for_push_notification(push_notification) do
      if token.endpoint_arn do
        result = @api_client.aws_publish(payload, token.endpoint_arn)

        case result do
          {:error, {:http_error, 400, %{code: "EndpointDisabled"}}} ->
            Flight.Repo.delete(token)
          #Logger.info("AWS SNS Endpoint disabled, deleting #{inspect(token)}")

          {:error, {:http_error, 400, %{code: "InvalidParameter"}}} ->
            Flight.Repo.delete(token)
          #Logger.info("AWS SNS invalid parameter, deleting device token #{inspect(token)}")

          {:error, error} ->
            Logger.error("Failed to send push notification. #{inspect(error)}")

          {:ok, _} ->
            #Logger.info("Successfully sent push notification to #{push_notification.user_id}")
            result
        end
      end
    end
  end

  # Helpers

  def apns_payload_for_push_notification(push_notification) do
    payload = %{
      alert: %{
        title: push_notification.title,
        body: push_notification.body
      }
    }

    payload =
      if push_notification.data do
        Map.put(payload, :fsm_data, push_notification.data)
      else
        payload
      end

    payload =
      if push_notification.update_badge do
        Map.put(payload, :badge, user_badge_count(push_notification.user_id))
      else
        payload
      end

    if push_notification.sound do
      Map.put(payload, :sound, "default")
    else
      payload
    end
  end

  def fcm_payload_for_push_notification(push_notification) do
    payload = %{
      notification: %{
        title: push_notification.title,
        body: push_notification.body
      },
      data: push_notification.data || %{}
    }

    if push_notification.sound do
      %{payload | notification: Map.put(payload.notification, :sound, "default")}
    else
      payload
    end
  end

  def sns_payload_for_push_notification(push_notification) do
    aps_payload =
      %{
        "aps" => apns_payload_for_push_notification(push_notification)
      }
      |> Poison.encode!()

    %{
      "APNS_SANDBOX" => aps_payload,
      "APNS" => aps_payload,
      "GCM" => fcm_payload_for_push_notification(push_notification) |> Poison.encode!()
    }
    |> Poison.encode!()
  end

  def tokens_for_push_notification(push_notification) do
    tokens_for_users([push_notification.user_id])
  end

  def tokens_for_users(user_ids) do
    Flight.Repo.all(from(t in Flight.Notifications.PushToken, where: t.user_id in ^user_ids))
  end

  def user_badge_count(_user_id) do
    0
  end
end
