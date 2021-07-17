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
    alias Fsm.Aircrafts.AircraftQueries

    alias Fsm.Aircrafts.Inspection
    alias Fsm.Aircrafts.InspectionData
    alias Fsm.Attachments.Attachment

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

    def get_user_custom_inspection_query(id, user_id) do
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
    def get_inspections(user_id, aircraft_id, page, per_page, filter) do
        inspection_data_query = from(t in InspectionData, order_by: [asc: t.sort])
        query =
          from i in Inspection,
            inner_join: a in Aircraft, on: a.user_id == ^user_id and i.aircraft_id == a.id,
            where: i.aircraft_id == ^aircraft_id,
            select: i
        inspections = query
        Logger.info fn -> "filter: #{inspect filter}" end

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

    @doc """
    Update an inspection with inspection data
    """
    def update_inspection(user_id, id, inspection_data) when is_list(inspection_data) do
        case is_owner(%{user_id: user_id, inspection_id: id}) do
            nil ->
                {:error, "not found"}
            _user ->
                case update_inspection_data(id, inspection_data) do
                    true ->                         
                        case is_inspection_values_set(id) do
                            {:true, inspection} ->
                                inspection
                                |> Inspection.changeset(%{updated: true})
                                |> Repo.update
                        end

                        {:ok, true}
                    false ->
                        {:error, "failed"}

                    error ->
                        error
                end
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

    def update_inspection(id, inspection_data) do
        {:error, "invalid format"}
    end

    def update_inspection_data(id, inspection_data) when is_list(inspection_data) do
        case get_inspection(id) do
            nil ->
                false
            inspection -> 
                updates = Enum.map(inspection_data, fn(kv) ->
                    db_insp_data = Enum.filter(inspection.inspection_data, fn(d) -> d.name == kv.name end)
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

    defp update_inspection_data_row(list = [hd | _], new_value) do

        case hd.type do
            :int ->
                {int_val, _} = Integer.parse(new_value.value)
                isd = Ecto.Changeset.change hd, t_int: int_val
                Repo.update isd
            :string ->
                isd = Ecto.Changeset.change hd, t_str: new_value.value
                Repo.update isd
            :date ->
                Logger.info fn -> "new_value.value: #{inspect new_value.value}" end
                Logger.info fn -> "Date.from_iso8601(new_value.value): #{inspect Date.from_iso8601(new_value.value)}" end
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
            :float ->
                {float_val, _} = Float.parse(new_value.value)
                isd = Ecto.Changeset.change hd, t_float: float_val
                Repo.update isd
        end
    end

    defp update_inspection_data_row([], _) do
    end

    def complete_inspection(user_id, input) do
        case is_owner(%{user_id: user_id, inspection_id: input.inspection_id}) do
            nil ->
                {:error, "inspection not found"}
            user ->
                inspection = Repo.get(Inspection, input.inspection_id)
                |> Repo.preload([:inspection_data])

                Logger.debug "input: #{inspect input}"
                completed_at = NaiveDateTime.utc_now()|> NaiveDateTime.truncate(:second)

                updateInspectionData = input
                    |> Map.merge(%{is_completed: true})
                    |> Map.merge(%{completed_at: completed_at})
                    |> Map.delete(:inspection_id)

                Logger.debug "updateInspectionData: #{inspect updateInspectionData}"

                Ecto.Changeset.change(inspection, updateInspectionData)
                |> Repo.update()

                create_from_inspection(inspection, updateInspectionData)
        end
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
        case should_repeat_inspection do
            true ->
                last_inspection_date = DateTime.utc_now()
                engine_tach_start  =  AircraftQueries.get_tach_engine_query(inspection.aircraft_id)
                |> Repo.one()
                |> case do
                       nil ->
                           0
                       engine ->
                           engine.engine_tach_start
                   end
                Logger.debug "engine_tach_start: #{inspect engine_tach_start}"


                insp_data =  Enum.map(inspection.inspection_data, fn(d) ->
                    case d.class_name do
                        "last_inspection" ->
                            case d.type do
                                :date ->
                                    Map.from_struct(d)
                                    |> Map.delete(:id)
                                    |> Map.put(:t_date, last_inspection_date)

                                :float ->
                                    Map.from_struct(d)
                                    |> Map.delete(:id)
                                    |> Map.put(:t_float, engine_tach_start)
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

                                :float ->
                                    case Map.has_key?(updateInspectionData, :tach_hours) do
                                        true->
                                            Map.from_struct(d)
                                            |> Map.delete(:id)
                                            |> Map.put(:t_float,updateInspectionData.tach_hours )
                                        _->
                                            Map.from_struct(d)
                                            |> Map.delete(:id)
                                            |> Map.put(:t_float, engine_tach_start+Application.get_env(:fboss, :default_next_tach_time_add))
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

                %Inspection{}
                |> Inspection.changeset(copy)
                |> Repo.insert
            false ->
                {:ok, inspection}
            end
    end

    def add_inspection(attrs \\ %{},current_user) do
        engine = AircraftQueries.get_tach_engine_query(attrs.aircraft_id) |> Repo.one()

        inspectionAttrs =
          attrs
            |> Map.put(:is_system_defined, false)
            |> Map.put(:aircraft_engine_id, engine.id)
            |> Map.merge(%{user_id: current_user.id})
            |> Map.merge(%{inspection_data: attrs.inspection_data |> map_inspection_data_value_to_field})

        %Inspection{}
        |> Inspection.changeset(inspectionAttrs)
        |> Repo.insert()
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

    @doc """
    Return user if inspection_id exists and belongs to user, otherwise nil
    """
    def is_owner(%{user_id: user_id, inspection_id: inspection_id}) do
        InspectionQueries.get_user_inspection_query(user_id, inspection_id)
        |> Repo.one
    end

end
