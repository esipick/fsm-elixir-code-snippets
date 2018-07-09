defmodule Flight.NotificationsFixtures do
  alias Flight.Notifications.{PushToken}
  alias Flight.{Repo}

  import Flight.AccountsFixtures

  def push_token_fixture(attrs \\ %{}, user \\ student_fixture()) do
    token =
      %PushToken{
        token: Flight.Random.hex(15),
        platform: "ios",
        user_id: user.id,
        endpoint_arn: "arn:that:aws:gave:me"
      }
      |> Map.merge(attrs)
      |> Repo.insert!()

    %{token | user: user}
  end
end
