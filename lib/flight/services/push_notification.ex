defmodule Mondo.PushNotification do
  defstruct [:title, :body, :sound, :user_id, data: nil, update_badge: false, filter: :all]
end
