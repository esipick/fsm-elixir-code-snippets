defmodule FlightWeb.Notification.NotificationController do
  use FlightWeb, :controller

  def index(conn, _) do
    notifications = [%{
      time: "08:19 P.M",
      title: "Appoinment deleted!"
    },
    %{
      time: "06:30 P.M",
      title: "Appoinment added!"
    },
    %{
      time: "10:20 A.M",
      title: "Some very very very very very very loonnnnng Notification"
    }
  ]
    render(
      conn,
      "index.html",
      notifications: notifications
    )
  end

end
