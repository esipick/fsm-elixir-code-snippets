defmodule Fsm.Squawks do
    @moduledoc """
    Squawks
    """

    import Ecto.Query, warn: false
    alias Flight.Repo
    require Logger
    alias Fsm.Squawks.Squawk
    alias Fsm.Aircrafts.Aircraft
    alias Fsm.Aircrafts
    alias Fsm.Accounts
    alias Fsm.Attachments.Attachment
    alias Fsm.Scheduling
    import Ecto.SoftDelete.Query
    alias Ecto.Multi

    def get_squawk(id) do
      query =  from s in Squawk,
                    left_join: at in Attachment, on: at.squawk_id == s.id and   is_nil(at.deleted_at),
                    where: s.id == ^id and is_nil(s.deleted_at) and s.resolved == false,
                    preload: [attachments: at]
      Repo.one(query)
    end

    def get_unresolved_squawk(id) do
      query =  from s in Squawk,
                    left_join: at in Attachment, on: at.squawk_id == s.id and   is_nil(at.deleted_at),
                    where: s.id == ^id and is_nil(s.deleted_at) and s.resolved == false,
                    preload: [attachments: at]
      Repo.one(query)
    end

    def get_squawk_by_id_and_user_id(id, user_id) do
      Squawk
      |> where([id: ^id, user_id: ^user_id])
      |> with_undeleted
      |> Repo.one()
    end

    def add_squawk_only(squawk_input)do
      #Logger.info fn -> "squawk_input----------------------: #{inspect squawk_input}" end
      resp  =
        %Squawk{}
        |> Squawk.changeset(squawk_input)
        |> Repo.insert()

      notify_squawk(:create, squawk_input)
      resp
    end

    def add_squawk(squawk_input, _, _)do
      resp =
        %Squawk{}
        |> Squawk.changeset(squawk_input)
        |> Repo.insert()

      notify_squawk(:create, squawk_input)
      resp
    end

    def fetch_aircraft_mechanic_user_ids(aircraft_id) do
      Scheduling.get_aircraft_appointments_mechanic_user_ids(aircraft_id)
    end

    def fetch_role_slug_user_ids(school_id, role_slugs) do
      Accounts.get_all_school_role_slug_user_ids(school_id, role_slugs)
    end

    def notify_squawk(:create, squawk_input) do
      Mondo.Task.start(fn ->
        Logger.info("Job:squawk_created_notification -- Sending...")

        creating_user = Accounts.get_user_by_user_id(squawk_input.user_id)
        squawk_input = Map.put(squawk_input, :aircraft, Aircrafts.get_aircraft_record_by_id(squawk_input.aircraft_id))

        users_to_notify =
          fetch_aircraft_mechanic_user_ids(squawk_input.aircraft_id)
          ++
          fetch_role_slug_user_ids(squawk_input.school_id, ["admin", "dispatcher"])
          |> Enum.uniq()
          |> Accounts.get_users_by_user_ids
        users_count = Enum.count(users_to_notify)

        Enum.map(users_to_notify, fn destination_user ->
          Flight.PushNotifications.squawk_created_notification(destination_user, creating_user, squawk_input)
          |> Mondo.PushService.publish()
        end)

        Logger.info("Job:squawk_created_notification -- Sent notifications to #{users_count} users.")
      end)
    end

    def notify_squawk(:update, old_squawk, squawk_input)do
      Mondo.Task.start(fn ->
        Logger.info("Job:squawk_updated_notification -- Sending...")

        creating_user = Accounts.get_user_by_user_id(old_squawk.user_id)
        old_squawk = Map.put(old_squawk, :aircraft, Aircrafts.get_aircraft_record_by_id(old_squawk.aircraft_id))
        users_to_notify =
          fetch_aircraft_mechanic_user_ids(old_squawk.aircraft_id)
          ++
          fetch_role_slug_user_ids(old_squawk.school_id, ["admin", "dispatcher"])
          |> Enum.uniq()
          |> Accounts.get_users_by_user_ids

        users_count = Enum.count(users_to_notify)
        Enum.map(users_to_notify, fn destination_user ->
          Flight.PushNotifications.squawk_updated_notification(destination_user, creating_user, old_squawk)
          |> Mondo.PushService.publish()
        end)

        Logger.info(
          "Job:squawk_updated_notification -- Sent notifications to #{users_count} users."
        )
      end)
    end


    def notify_squawk(:delete, squawk_input)do
      Mondo.Task.start(fn ->
        Logger.info("Job:squawk_deleted_notification -- Sending...")

        creating_user = Accounts.get_user_by_user_id(squawk_input.user_id)
        squawk_input = Map.put(squawk_input, :aircraft, Aircrafts.get_aircraft_record_by_id(squawk_input.aircraft_id))
        users_to_notify =
          fetch_aircraft_mechanic_user_ids(squawk_input.aircraft_id)
          ++
          fetch_role_slug_user_ids(squawk_input.school_id, ["admin", "dispatcher"])
          |> Enum.uniq()
          |> Accounts.get_users_by_user_ids

        users_count = Enum.count(users_to_notify)
        Enum.map(users_to_notify, fn destination_user ->
          Flight.PushNotifications.squawk_deleted_notification(destination_user, creating_user, squawk_input)
          |> Mondo.PushService.publish()
        end)

        Logger.info(
          "Job:squawk_deleted_notification -- Sent notifications to #{
            users_count
          } users."
        )
      end)
    end

    def add_multiple_squawk_images(squawk_images_input) do
      Multi.new
      |> Multi.run(:add_squawk_image, &(add_multiple_squawk_images(squawk_images_input, &1, &2)))
      |> Repo.transaction
      |> case do
        {:ok, result} -> {:ok, result.add_squawk_image}
        {:error, _error, error, %{}} ->
          {:error, error}
      end
    end

    def add_multiple_squawk_images(squawk_images_input, _opt1, _opt2) do
      Enum.reduce_while(squawk_images_input, {:ok, []}, fn squawk_image, acc ->
        user_id = Map.get(squawk_image, :user_id)
        squawk_id = Map.get(squawk_image, :squawk_id)

        add_squawk_image(squawk_image, %{user_id: user_id}, nil, %{add_squawk: %{id: squawk_id}})
        |> case do
          {:ok, squawk_image_changeset} ->
            {:ok, acc} = acc
            {:cont, {:ok, [squawk_image_changeset | acc]}}

          {:error, changeset} ->
            {:halt, {:error, changeset}}
        end

      end)
    end

    def add_squawk_image(squawk_image_input,squawk_input, _opt1, %{add_squawk: %{id: squawk_id}}) do
        squawk_image_input = Map.put(squawk_image_input, :squawk_id, squawk_id)
                             |> Map.put(:user_id, squawk_input.user_id)
        %Attachment{}
        |> Attachment.changeset(squawk_image_input)
        |> Repo.insert()
    end

    def add_squawk_and_image(squawk_input, squawk_image_input) do
      Multi.new
      |> Multi.run(:add_squawk, &add_squawk(squawk_input, &1, &2))
      |> Multi.run(:add_squawk_image, &add_squawk_image(squawk_image_input,squawk_input,&1, &2))
      |> Repo.transaction
      |> case  do
           {:ok, result} ->
            notify_squawk(:create, squawk_input)
             {:ok, result.add_squawk}
           {:error, _error, error, %{}} ->
             {:error, error}
         end
    end

    def get_squawks({aircraft_id, user_id}) do

      case aircraft_id do
        nil -> []
        _ ->
          query = from s in Squawk,
          left_join: at in Attachment, on: at.squawk_id == s.id and   is_nil(at.deleted_at),
          order_by: [desc: s.inserted_at],
          where: s.aircraft_id == ^aircraft_id and is_nil(s.deleted_at) and s.resolved == false,
          preload: [attachments: at]

          Repo.all(query)
      end
    end

    def get_squawks(aircrafts) when is_list(aircrafts)do
      aircraft_ids = Enum.map(aircrafts, & &1.id)

      query = from s in Squawk,
      left_join: a in Aircraft, on: a.id == s.aircraft_id,
      left_join: at in Attachment, on: at.squawk_id == s.id and   is_nil(at.deleted_at),
      order_by: [desc: s.inserted_at],
      where: s.aircraft_id in ^aircraft_ids and is_nil(s.deleted_at) and s.resolved == false,
      preload: [attachments: at, aircraft: a]

      Repo.all(query)
    end

    def get_squawks(aircraft_id) do

      query = from s in Squawk,
      left_join: a in Aircraft, on: a.id == s.aircraft_id,
      left_join: at in Attachment, on: at.squawk_id == s.id and   is_nil(at.deleted_at),
      order_by: [desc: s.inserted_at],
      where: s.aircraft_id == ^aircraft_id and is_nil(s.deleted_at) and s.resolved == false,
      preload: [attachments: at, aircraft: a]

      Repo.all(query)
    end

    def update_squawk(squawk, attrs) do
      resp =
        squawk
        |> Squawk.changeset(attrs)
        |> Repo.update()

      notify_squawk(:update, squawk, attrs)
      resp
    end

    def delete_squawk(squawk) do
      resp =
        Repo.soft_delete(squawk)

      notify_squawk(:delete, squawk)
      resp
    end

    def add_squawk_image(attrs) do
      %Attachment{}
      |> Attachment.changeset(attrs)
      |> Repo.insert()
    end

    def get_squawk_image(id, user_id) do
      Attachment
      |> where([id: ^id, user_id: ^user_id])
      |> with_undeleted
      |> Repo.one()
    end

    def delete_squawk_image(attachment) do
      Repo.soft_delete(attachment)
    end
end
