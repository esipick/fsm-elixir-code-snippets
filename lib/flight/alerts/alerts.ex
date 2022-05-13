defmodule Flight.Alerts do
    alias Flight.Alerts.Alert
    alias Flight.Alerts.AlertsQueries
    alias Flight.Accounts
    alias Flight.Repo
    alias Flight.SchoolScope
    import Ecto.Query, warn: false

    # def create_notification_alerts(alerts) do
    #     Repo.insert_all(Alert, alerts)
    # end

    def get_alert(id, school_context) do
        Alert
        |> SchoolScope.scope_query(school_context)
        |> where([a], a.id == ^id)
        |> Repo.one()
    end

    def create_notification_alert(alert) do
        %Alert{}
        |> Alert.changeset(alert)
        |> Repo.insert
    end

    def list_alerts(page, per_page, sort_field, sort_order, filter, context) do
        AlertsQueries.list_alerts_query(page, per_page, sort_field, sort_order, filter, context)
        |> Repo.all()
    end

    def create_squawk_alert_and_notify_roles(_squawk_id, _school_id, _sender_id, nil), do: {:ok, []}
    def create_squawk_alert_and_notify_roles(_squawk_id, _school_id, _sender_id, []), do: {:ok, []}
    def create_squawk_alert_and_notify_roles(squawk_id, school_id, sender_id, roles) do
        alert = %{
            code: :squawk_issue,
            title: "Squawk Alert",
            description: "This is so much important",
            priority: :top,
            school_id: school_id,
            sender_id: sender_id,
            additional_info: %{squawk_id: squawk_id}
        }

        alerts =
            school_id
            |> Accounts.get_school_users_by_roles(roles)
            # |> Enum.map(&(Map.put(alert, :receiver_id, &1.id)))
            |> MapSet.new
            |> Enum.map(fn(item) ->
                Alert.changeset(%Alert{}, Map.put(alert, :receiver_id, item.id))
            end)

        valid = Enum.all?(alerts, &(&1.valid?))

        if valid do
            alerts = Enum.map(alerts, &(&1.changes))
            {_, _} = Repo.insert_all(Alert, alerts)
            {:ok, []}

        else
            {:error, "Couldn't create squawk alerts, Please try again."}
        end
    end
end
