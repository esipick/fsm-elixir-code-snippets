defmodule Fsm.Inspections do
    @moduledoc """
    The Aircraft Inspections context.
    """

    import Ecto.Query, warn: false
    alias Flight.Repo
    require Logger
    import Ecto.SoftDelete.Query
    alias Fsm.Scheduling.Aircraft
    alias Fsm.Aircrafts.InspectionQueries
    alias Fsm.Aircrafts.AircraftsQueries

    alias Fsm.Aircrafts.Inspection
    alias Fsm.Aircrafts.InspectionData
    alias Fsm.Attachments.Attachment
    alias Fsm.Aircrafts.InspectionNotesAuditTrail
    alias Ecto.Multi

    def get_inspection(id) do
        Inspection
            |> where([id: ^id])
            |> with_undeleted
            |> Repo.one()
            |>Repo.preload([:inspection_data, :attachments])
    end

    def get_inspection_by_inspection_id(inspection_id) do
        inspection =  Inspection
        |> where([id: ^inspection_id])
        |> with_undeleted
        |> Repo.one()
        |> Repo.preload([:inspection_data, :attachments])

        changed_data = Enum.map(inspection.inspection_data, fn(d) ->
            %{d | value: InspectionData.value_from_t_field(d)}
        end)

        %{inspection | inspection_data: changed_data}
    end

    def get_user_custom_inspection_query(id) do
        Inspection
        |> where([id: ^id])
        |> with_undeleted
        |> Repo.one()
    end

    def delete_inspection(inspection) do
        Repo.soft_delete(inspection)
    end

    @doc """
    Get aircraft inspections or nil
    """
    def get_inspections(aircraft_id, page, per_page, filter) do
        inspection_data_query = from(t in InspectionData, order_by: [asc: t.sort])
        query =
          from i in Inspection,
            where: i.aircraft_id == ^aircraft_id,
            select: i
        inspections = query
        #Logger.info fn -> "filter: #{inspect filter}" end

        case filter != nil && Map.has_key?(filter, :sort_field) && Map.has_key?(filter, :sort_order) do
            true->
                inspections = inspections
                              |> sort_by(Map.get(filter, :sort_field), Map.get(filter, :sort_order))
            false->
                Logger.info fn -> "filter000" end

        end

        inspections =
          inspections
            |> filter(filter)
            |> paginate(page, per_page)
            |> with_undeleted
            |> Repo.all
            |> Repo.preload([[inspection_data: inspection_data_query], :attachments])

        Enum.map(inspections, fn(is) ->
            changed_data = Enum.map(is.inspection_data, fn(d) ->
                %{d | value: InspectionData.value_from_t_field(d)}
            end)

            %{is | inspection_data: changed_data}
        end)
    end

    def get_inspections(aircraft_id) do
        inspection_data_query = from(t in InspectionData, order_by: [asc: t.sort])
        query =
          from i in Inspection,
            where: i.aircraft_id == ^aircraft_id,
            order_by: [desc: i.inserted_at],
            select: i

        inspections = query
            |> with_undeleted
            |> Repo.all
            |> Repo.preload([[inspection_data: inspection_data_query], :attachments])

        Enum.map(inspections, fn(is) ->
            changed_data = Enum.map(is.inspection_data, fn(d) ->
                %{d | value: InspectionData.value_from_t_field(d)}
            end)

            %{is | inspection_data: changed_data}
        end)
    end

    def paginate(query, 0, 0) do
        query
    end

    def paginate(query, 0, size) do
        from query,
             limit: ^size
    end

    def paginate(query, page, size) do
        from query,
             limit: ^size,
             offset: ^((page-1) * size)
    end

    defp sort_by(query, nil, nil) do
        query
    end

    defp sort_by(query, sort_field, sort_order) do
        from g in query,
             order_by: [{^sort_order, field(g, ^sort_field)}]
    end

    defp filter(query, nil) do
        query
    end

    defp filter(query, filter) do
        Enum.reduce(filter, query, fn ({key, value}, query) ->
            case key do
                :id ->
                    from a in query,
                         where: a.id == ^value

                :aircraft_id ->
                    from a in query,
                         where: a.aircraft_id == ^value

                :type ->
                    from a in query,
                         where: a.type == ^value

                :name ->
                    from a in query,
                         where: a.name == ^value

                :value ->
                    from a in query,
                         where: a.value == ^value

                :class_name ->
                    from a in query,
                         where: a.class_name == ^value

                :completed ->
                    from a in query,
                         where: a.is_completed == ^value

                _ ->
                    query
            end
        end)
    end

    defp notes_audit_trail(inspection_id, params) do
        user_id = Map.get(params, :user_id)
        notes = Map.get(params, :notes)
        notes = if notes == "", do: nil, else: notes
        status = if Map.has_key?(params, :notes), do: :ok, else: :no_update

        {status, %{user_id: user_id, inspection_id: inspection_id, notes: notes}}
    end

    @doc """
    Update an inspection with inspection data
    """
    def update_inspection(id, params, inspection_data) when is_list(inspection_data) do
        case update_inspection_data(id, inspection_data) do
            true ->
                case is_inspection_values_set(id) do
                    {:true, inspection} ->
                        {status, audit_trail} = notes_audit_trail(id, params)
                        notes = Map.get(audit_trail, :notes)

                        insp_params = %{updated: true}
                        insp_params =
                            if status == :ok, do: Map.put(insp_params, :notes, notes), else: insp_params

                        inspection
                        |> Inspection.changeset(insp_params)
                        |> Repo.update
                        |> case do
                            {:ok, new_inspection} ->

                                if status == :ok do
                                    update_notes_if_can(audit_trail, inspection)
                                end

                                {:ok, new_inspection}

                            other ->
                                other
                        end
                end

                {:ok, true}
            false ->
                {:error, "failed"}

            error ->
                error
        end
    end

    def is_inspection_values_set(id) do
        inspection = get_inspection(id)

        case Enum.filter(inspection.inspection_data, fn(s) ->
            InspectionData.value_from_t_field(s) == ""
        end) do
            [] ->
                {:true, inspection}
            [hd | _] ->
                {:false}
        end
    end

    def update_inspection(id, _, inspection_data) do
        {:error, "invalid format"}
    end

    def update_inspection_data(id, inspection_data) when is_list(inspection_data) do
        case get_inspection(id) do
            nil ->
                false
            inspection ->
                updates = Enum.map(inspection_data, fn(kv) ->
                    db_insp_data = Enum.filter(inspection.inspection_data, fn(d) -> d.class_name == kv.class_name end)
                    update_inspection_data_row(db_insp_data, kv)
                end)

                Enum.find(updates, true, fn(u) ->
                    case u do
                        {:error, error} -> true
                        _ -> false
                    end
                end)
        end
    end

    def add_multiple_inspection_images(inspection_images_input) do
        Multi.new
        |> Multi.run(:add_inspection_image, &(add_multiple_inspection_images(inspection_images_input, &1, &2)))
        |> Repo.transaction
        |> case do
               {:ok, result} -> {:ok, result.add_inspection_image}
               {:error, _error, error, %{}} ->
                   {:error, error}
           end
    end

    def add_multiple_inspection_images(inspection_images_input, _opt1, _opt2) do
        Enum.reduce_while(inspection_images_input, {:ok, []}, fn inspection_image, acc ->
            user_id = Map.get(inspection_image, :user_id)
            inspection_id = Map.get(inspection_image, :inspection_id)

            add_inspection_image(inspection_image, %{user_id: user_id}, nil, %{add_inspection: %{id: inspection_id}})
            |> case do
                   {:ok, inspection_image_changeset} ->
                       {:ok, acc} = acc
                       {:cont, {:ok, [inspection_image_changeset | acc]}}

                   {:error, changeset} ->
                       {:halt, {:error, changeset}}
               end

        end)
    end

    def add_inspection_image(inspection_image_input,inspection_input, _opt1, %{add_inspection: %{id: inspection_id}}) do
        inspection_image_input = Map.put(inspection_image_input, :inspection_id, inspection_id)
                             |> Map.put(:user_id, inspection_input.user_id)
        %Attachment{}
        |> Attachment.changeset(inspection_image_input)
        |> Repo.insert()
    end

    defp update_inspection_data_row(list = [hd | _], new_value) do

        case hd.type do
            :int ->
                case new_value.type do
                    :int ->
                        {int_val, _} = Integer.parse(new_value.value)
                        Ecto.Changeset.change hd, t_int: int_val
                    :float ->
                        {float_val, _} = Float.parse(new_value.value)
                        Ecto.Changeset.change hd, t_float: float_val, type: :float, t_int: nil
                end
                |> Repo.update
            :float ->
                case new_value.type do
                    :int ->
                        {int_val, _} = Integer.parse(new_value.value)
                        isd = Ecto.Changeset.change hd, t_int: int_val, type: :int, t_float: nil
                    :float ->
                        {float_val, _} = Float.parse(new_value.value)
                        isd = Ecto.Changeset.change hd, t_float: float_val
                end
                |> Repo.update
            :string ->
                isd = Ecto.Changeset.change hd, t_str: new_value.value
                Repo.update isd
            :date ->
              #Logger.info fn -> "new_value.value: #{inspect new_value.value}" end
              #Logger.info fn -> "Date.from_iso8601(new_value.value): #{inspect Date.from_iso8601(new_value.value)}" end
                case Date.from_iso8601(new_value.value) do
                    {:ok, iso_date} ->
                        isd = Ecto.Changeset.change hd, t_date: iso_date
                        Repo.update isd
                    {:error, reason} ->
                        cond do
                            Kernel.is_atom(reason) ->
                                reason = Atom.to_string(reason) |> String.replace("_"," ")
                                {:error, new_value.name<> ": "<>reason}
                            Kernel.is_binary(reason) ->
                                {:error, new_value.name<> ": "<>reason}
                            reason ->
                                {:error, reason}
                        end
                end
        end
    end

    defp update_inspection_data_row([], _) do
    end

    def complete_inspection(input) do
        inspection = Repo.get(Inspection, input.inspection_id)
        |> Repo.preload([:inspection_data])
        is_repeated = input.is_repeated
        Logger.debug "input: #{inspect input}"
        completed_at = NaiveDateTime.utc_now()|> NaiveDateTime.truncate(:second)

        updateInspectionData = input
            |> Map.merge(%{is_completed: true})
            |> Map.merge(%{is_repeated: is_repeated})
            |> Map.merge(%{completed_at: completed_at})
            |> Map.delete(:inspection_id)



        Ecto.Changeset.change(inspection, updateInspectionData)
        |> Repo.update()
        Logger.debug "updateInspectionData: #{inspect updateInspectionData}"
        create_from_inspection(inspection, updateInspectionData)
    end

    def create_from_inspection(inspection, updateInspectionData) do
        should_repeat_inspection =  case Map.get(updateInspectionData, :is_repeated) do
            nil->
                false
            true->
               true
            false->
               false
        end
        Logger.debug "should_repeat_inspection---: #{inspect should_repeat_inspection}"
        case should_repeat_inspection do
            true ->
                last_inspection_date = DateTime.utc_now()
                #engine_tach_start  =  AircraftsQueries.get_tach_engine_query(inspection.aircraft_id)
                aircraft = Repo.get_by(Aircraft, id: inspection.aircraft_id)
                engine_tach_start = aircraft.last_tach_time
                engine_tach_start = Flight.Format.hours_from_tenths(engine_tach_start) |> Decimal.cast()  |> Decimal.round(1)
                engine_tach_start_string = engine_tach_start |> Decimal.to_string()

                insp_data =  Enum.map(inspection.inspection_data, fn(d) ->
                    case d.class_name do
                        "last_inspection" ->
                            case d.type do
                                :date ->
                                    Map.from_struct(d)
                                    |> Map.delete(:id)
                                    |> Map.put(:t_date, last_inspection_date)
                                _ ->
                                    case Integer.parse(engine_tach_start_string) do
                                        {int_val, int_rest} ->
                                            case int_rest == "" or int_rest == ".0" do
                                                true ->
                                                    Map.from_struct(d)
                                                    |> Map.delete(:id)
                                                    |> Map.put(:t_float, nil)
                                                    |> Map.put(:type, :int)
                                                    |> Map.put(:t_int, int_val)
                                                false ->
                                                    Map.from_struct(d)
                                                    |> Map.delete(:id)
                                                    |> Map.put(:t_int, nil)
                                                    |> Map.put(:type, :float)
                                                    |> Map.put(:t_float, engine_tach_start)
                                            end
                                    end
                            end
                        "next_inspection" ->
                            case d.type do
                                :date ->
                                    case Map.has_key?(updateInspectionData, :next_inspection) do
                                        true->
                                            Map.from_struct(d)
                                            |> Map.delete(:id)
                                            |> Map.put(:t_date, updateInspectionData.next_inspection)
                                        _->
                                            Map.from_struct(d)
                                            |> Map.delete(:id)
                                            |> Map.put(:value, "")
                                    end
                                _ ->
                                    case Map.has_key?(updateInspectionData, :tach_hours) do
                                        true->
                                            case Integer.parse(updateInspectionData.tach_hours) do
                                                {int_val, int_rest} ->
                                                    case int_rest == "" or int_rest == ".0" do
                                                        true ->
                                                            Map.from_struct(d)
                                                            |> Map.delete(:id)
                                                            |> Map.put(:type, :int)
                                                            |> Map.put(:t_int, int_val)
                                                            |> Map.put(:t_float, nil)
                                                        false ->
                                                            Map.from_struct(d)
                                                            |> Map.delete(:id)
                                                            |> Map.put(:type, :float)
                                                            |> Map.put(:t_int, nil)
                                                            |> Map.put(:t_float, updateInspectionData.tach_hours)
                                                    end
                                            end
                                        _->
                                            Map.from_struct(d)
                                            |> Map.delete(:id)
                                            |> Map.put(:type, :float)
                                            |> Map.put(:t_int, nil)
                                    end
                            end
                        _ ->
                            case d.type do
                                :date ->
                                    Map.from_struct(d)
                                    |> Map.delete(:id)
                                    |> Map.put(:t_date, nil)

                                :float ->
                                    Map.from_struct(d)
                                    |> Map.delete(:id)

                            end

                    end
                end)

                copy = Map.from_struct(inspection)
                       |> Map.drop([:id, :note, :is_completed,:completed_at, :is_repeated, :repeat_every_days])
                       |> Map.merge(%{inspection_data: insp_data})
                Logger.debug "copy: #{inspect copy}"
                %Inspection{}
                |> Inspection.changeset(copy)
                |> Repo.insert
                |> IO.inspect()
            false ->
                {:ok, inspection}
            end
    end

    def add_inspection(attrs \\ %{},current_user) do
        engine = AircraftsQueries.get_tach_engine_query(attrs.aircraft_id) |> Repo.one() || %{}

        engine_id = Map.get(engine, :id)

        inspectionAttrs =
          attrs
            |> Map.put(:is_system_defined, false)
            |> Map.put(:updated, true)
            |> Map.put(:aircraft_engine_id, engine_id)
            |> Map.merge(%{user_id: current_user.id})
            |> Map.merge(%{inspection_data: attrs.inspection_data |> map_inspection_data_value_to_field})

        %Inspection{}
        |> Inspection.changeset(inspectionAttrs)
        |> Repo.insert()
        |> case do
            {:ok, %{notes: notes} = inspection} ->
                trail = %{
                    notes: notes,
                    user_id: inspection.user_id,
                    inspection_id: inspection.id
                }
                create_notes_audit_trail(trail, false)

                {:ok, inspection}

            other ->
                other
        end
    end

    defp map_inspection_data_value_to_field(inspections_data) do
        Enum.map(inspections_data, fn inspection_data ->
            case inspection_data.type do
                :int ->
                    {int_val, _} = Integer.parse(inspection_data.value)
                    Map.put(inspection_data, :t_int, int_val)
                :string ->
                    Map.put(inspection_data, :t_str, inspection_data.value)
                :date ->
                    case Date.from_iso8601(inspection_data.value) do
                        {:ok, iso_date} ->
                            Map.put(inspection_data, :t_date, iso_date)
                        {:error, reason} ->
                            cond do
                                Kernel.is_atom(reason) ->
                                    reason = Atom.to_string(reason) |> String.replace("_"," ")
                                    {:error, inspection_data.name<> ": "<>reason}
                                Kernel.is_binary(reason) ->
                                    {:error, inspection_data.name<> ": "<>reason}
                                reason ->
                                    {:error, reason}
                            end
                    end
                :float ->
                {float_val, _} = Float.parse(inspection_data.value)
                Map.put(inspection_data, :t_float, float_val)
            end
        end)
    end

    defp update_notes_if_can(%{user_id: nil}, nil), do: {:error, "user_id can't be nil."}
    defp update_notes_if_can(%{notes: notes}, %Inspection{notes: notes}), do: {:error, "nothing to update"}
    defp update_notes_if_can(params, %Inspection{} = inspection) do
        create_notes_audit_trail(params, true)
        {:ok, :done}
    end

    defp create_notes_audit_trail(%{notes: nil}, false = _force_insert_nil), do: {:error, "notes cannot be nil"}
    defp create_notes_audit_trail(params, _) do
        %InspectionNotesAuditTrail{}
        |> InspectionNotesAuditTrail.changeset(params)
        |> Repo.insert
    end

    @doc """
    Return user if inspection_id exists and belongs to user, otherwise nil
    """
    def is_owner(%{user_id: user_id, inspection_id: inspection_id}) do
        InspectionQueries.get_inspection_owner_query(user_id, inspection_id)
        |> Repo.one
    end

end
