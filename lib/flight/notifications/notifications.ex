defmodule Flight.Notifications do
  alias Flight.Repo
  alias Flight.Notifications.{PushToken}

  import Ecto.Query, warn: false

  def update_push_token(%{"token" => token, "platform" => platform}, user_id) do
    existing_token = push_token(token, platform)
    if existing_token do
      existing_token
      |> PushToken.changeset(%{user_id: user_id})
      |> Repo.update()
    else
        case platform do
          "ios" ->
            Mondo.PushService.create_ios_endpoint(token)
            |> case do
                 {:error, {:http_error, 400, %{message: "Invalid parameter: Token Reason: iOS device tokens must be no more than 400 hexadecimal characters"}}} ->
                   Mondo.PushService.create_android_endpoint(token)
                 resp ->
                   resp
               end
          "android" -> Mondo.PushService.create_android_endpoint(token)
        end
        |> case do
             {:ok, endpoint_arn} ->
               %PushToken{}
               |> PushToken.changeset(%{
                 token: token,
                 platform: platform,
                 endpoint_arn: endpoint_arn,
                 user_id: user_id
               })
               |> Repo.insert()
             {:error, {:http_error, 400, %{message: message}}} -> {:error, message}
             error ->
              error
           end
    end
  end

  def push_token(token, platform) when platform in ["ios", "android"] do
    Ecto.Query.from(t in PushToken, where: t.token == ^token and t.platform == ^platform)
    |> Repo.one()
  end
end
