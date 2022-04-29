defmodule Flight.Squawks do
    alias Flight.Repo

    alias Flight.Alerts
    alias Flight.Inspections.{
        Squawk,
        Queries,
        SquawkAttachment
    }

    def get_all_squawks(page, per_page, sort_field, sort_order, filter) do
        Queries.get_all_squawks_query(page, per_page, sort_field, sort_order, filter)
        |> Repo.all
    end

    def get_squawk(id, school_id) do
        Squawk
        |> Repo.get_by(id: id, school_id: school_id)
        |> Repo.preload([:attachments])
        |> map_squawk_attachment_urls
        |> case do
            nil -> {:error, "Squawk with id not found."}
            squawk -> {:ok, squawk}
        end
    end

    def create_squawk_and_notify(attrs) do
        roles = Map.get(attrs, "notify_roles")
        school_id = Map.get(attrs, "school_id")
        created_by_id = Map.get(attrs, "created_by_id")

        Repo.transaction(fn ->
            with {:ok, %{id: id} = squawk} <- create_squawk(attrs),
            {:ok, _} <- upload_squawk_attachments(id, Map.get(attrs, "attachments")) do
                Alerts.create_squawk_alert_and_notify_roles(id, school_id, created_by_id, roles)
                {:ok, squawk}
            else
                {:error, error} -> Repo.rollback(error)
            end
        end)
    end

    def delete_squawk_attachment(id, squawk_id, school_id) do
        query =
            Queries.squawk_attachment_query(id, squawk_id, school_id)

        with %{id: _} = attach <- Repo.get_by(query, []),
            {:ok, _} <- Repo.delete(attach) do
                Flight.SquawksUploader.delete({attach.attachment, attach})

            {:ok, attach}

        else
            nil -> {:error, "Attachment not found."}
            error -> error
        end
    end

    defp upload_squawk_attachments(_, nil), do: {:ok, []}
    defp upload_squawk_attachments(squawk_id, attrs) when is_map(attrs) do
        upload_squawk_attachments(squawk_id, [attrs])
        |> case do
            {:ok, attachments} -> {:ok, List.first(attachments)}
            error -> error
        end
    end

    defp upload_squawk_attachments(squawk_id, attrs) when is_list(attrs) do
        Enum.reduce_while(attrs, {:ok, []}, fn item, {:ok, acc} ->
            %SquawkAttachment{}
            |> SquawkAttachment.changeset(%{squawk_id: squawk_id, attachment: item})
            |> Repo.insert
            |> case do
                {:ok, changeset} -> {:cont, {:ok, [changeset | acc]}}
                error -> {:halt, error}
            end
        end)
    end

    defp create_squawk(attrs) do
        %Squawk{}
        |> Squawk.changeset(attrs)
        |> Repo.insert
    end

    defp map_squawk_attachment_urls(nil), do: nil
    defp map_squawk_attachment_urls(squawk) do
        attachments =
            Enum.map(squawk.attachments, fn item ->
                urls = Flight.SquawksUploader.urls({item.attachment, item})
                urls = %{original: urls[:original], thumb: urls[:thumb]}

                item
                |> Map.delete(:__struct__)
                |> Map.merge(urls)
            end)

        squawk
        |> Map.delete(:__struct__)
        |> Map.put(:attachments, attachments)
    end
end
