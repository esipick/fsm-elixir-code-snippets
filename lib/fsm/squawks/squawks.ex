defmodule Fsm.Squawks do
    @moduledoc """
    Squawks
    """

    import Ecto.Query, warn: false
    alias Flight.Repo
    require Logger
    alias Fsm.Squawks.Squawk
    alias Fsm.Attachments.Attachment
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
      %Squawk{}
      |> Squawk.changeset(squawk_input)
      |> Repo.insert()
    end

    def add_squawk(squawk_input, _, _)do
      %Squawk{}
      |> Squawk.changeset(squawk_input)
      |> Repo.insert()
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

    def update_squawk(squawk, attrs) do
      squawk
      |> Squawk.changeset(attrs)
      |> Repo.update()
    end

    def delete_squawk(squawk) do
      Repo.soft_delete(squawk)
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
