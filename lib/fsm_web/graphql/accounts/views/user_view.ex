defmodule FsmWeb.GraphQL.Accounts.UserView do

  def map(user) when is_map(user) do
    roles = Map.get(user, :roles)
    user = (Map.get(user, :user) || %{})

    Map.merge(user,
      %{avatar: avatar_urls_map(user),
      roles: roles
      }
    )
  end

  def map(users) when is_list(users) do
    Enum.map(users, fn user ->
      map(user)
    end)
  end

  def map(users) do
    users
  end

  defp avatar_urls_map(%{avatar: %{file_name: avatar}} = user)
       when avatar != nil do
    urls = Flight.AvatarUploader.urls({avatar, user})
    %{original: urls[:original], thumb: urls[:thumb]}
  end

  defp avatar_urls_map(%{avatar: avatar} = user)
       when avatar != nil do
    urls = Flight.AvatarUploader.urls({avatar, user})
    %{original: urls[:original], thumb: urls[:thumb]}
  end

  defp avatar_urls_map(user) do
    Map.get(user, :avatar)
  end
end
